// =============================================================================
// BMC Finals Project - student_shop
// `create-invoice` edge function
//
// Creates a Xendit invoice for a product and stores a PENDING order.
//
// The Flutter app sends:
//   { "product_name": "Mechanical Gaming Keyboard", "amount": 1500 }
//
// and receives:
//   { "invoice_url": "https://checkout.xendit.co/...", "external_id": "..." }
//
// The order is created with the SERVICE ROLE key, so the client can never
// write to the `orders` table on its own.
// =============================================================================

import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const XENDIT_API_URL = 'https://api.xendit.co/v2/invoices';

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const secretKey = Deno.env.get('XENDIT_SECRET_KEY') ?? '';
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY') ?? '';

  if (!secretKey || !supabaseUrl || !serviceRoleKey) {
    return json({ error: 'The function secrets are not configured.' }, 500);
  }

  let payload: {
    product_name?: string;
    amount?: number;
    customer?: {
      name?: string;
      email?: string;
      phone?: string;
      street_address?: string;
      city?: string;
      province?: string;
      postal_code?: string;
    };
  };
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'The request body is not valid JSON.' }, 400);
  }

  const productName = String(payload.product_name ?? '').trim();
  const amount = Number(payload.amount);
  const customer = {
    name: String(payload.customer?.name ?? '').trim(),
    email: String(payload.customer?.email ?? '').trim(),
    phone: String(payload.customer?.phone ?? '').trim(),
    streetAddress: String(payload.customer?.street_address ?? '').trim(),
    city: String(payload.customer?.city ?? '').trim(),
    province: String(payload.customer?.province ?? '').trim(),
    postalCode: String(payload.customer?.postal_code ?? '').trim(),
  };

  if (!productName) {
    return json({ error: 'product_name is required' }, 400);
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    return json({ error: 'amount must be a positive number' }, 400);
  }
  if (
    !customer.name || !customer.email || !customer.phone ||
    !customer.streetAddress || !customer.city || !customer.province ||
    !customer.postalCode
  ) {
    return json({ error: 'All customer and delivery details are required.' }, 400);
  }
  const emailParts = customer.email.split('@');
  if (
    emailParts.length !== 2 || !emailParts[0] ||
    !emailParts[1].includes('.') || emailParts[1].startsWith('.') ||
    emailParts[1].endsWith('.')
  ) {
    return json({ error: 'A valid email address is required.' }, 400);
  }

  const externalId = `order-${crypto.randomUUID()}`;

  // ---------------------------------------------------------------------------
  // 1. ask Xendit for an invoice
  // ---------------------------------------------------------------------------
  const paymentMethods = (Deno.env.get('XENDIT_PAYMENT_METHODS') ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);

  const invoiceResponse = await fetch(XENDIT_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${btoa(`${secretKey}:`)}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      external_id: externalId,
      amount,
      currency: 'PHP',
      description: productName,
      customer: {
        given_names: customer.name,
        email: customer.email,
        mobile_number: customer.phone,
        addresses: [{
          street_line1: customer.streetAddress,
          city: customer.city,
          province_state: customer.province,
          postal_code: customer.postalCode,
          country: 'PH',
        }],
      },
      payment_methods: paymentMethods.length > 0 ? paymentMethods : undefined,
      success_redirect_url: 'https://checkout.xendit.co/success',
      failure_redirect_url: 'https://checkout.xendit.co/failure',
    }),
  });

  const invoice = await invoiceResponse.json();

  if (!invoiceResponse.ok) {
    const message =
      invoice?.error_code && invoice?.message
        ? `${invoice.error_code}: ${invoice.message}`
        : `Xendit answered with HTTP ${invoiceResponse.status}.`;
    return json({ error: message }, 502);
  }

  // ---------------------------------------------------------------------------
  // 2. store the pending order (service role - the client cannot do this)
  // ---------------------------------------------------------------------------
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error } = await admin.from('orders').insert({
    external_id: externalId,
    status: 'PENDING',
    product_name: productName,
    amount,
  });

  if (error) {
    console.error('the order could not be stored', error);
    return json({ error: 'The order could not be stored.' }, 500);
  }

  const { error: customerDetailsError } = await admin
    .from('order_customer_details')
    .insert({
      external_id: externalId,
      customer_name: customer.name,
      customer_email: customer.email,
      customer_phone: customer.phone,
      shipping_address: customer.streetAddress,
      shipping_city: customer.city,
      shipping_province: customer.province,
      shipping_postal_code: customer.postalCode,
    });

  if (customerDetailsError) {
    console.error('customer delivery details could not be stored', customerDetailsError);
    return json({ error: 'The customer details could not be stored.' }, 500);
  }

  return json({
    invoice_id: invoice.id,
    invoice_url: invoice.invoice_url,
    external_id: externalId,
    amount,
    currency: invoice.currency ?? 'PHP',
  });
});
