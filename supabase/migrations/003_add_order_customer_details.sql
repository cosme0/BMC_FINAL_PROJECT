-- Keep personal delivery information separate from the publicly readable order
-- status table. Only the service-role Edge Function can access this table.
create table if not exists public.order_customer_details (
    external_id         text primary key references public.orders (external_id) on delete cascade,
    customer_name       text not null,
    customer_email      text not null,
    customer_phone      text not null,
    shipping_address    text not null,
    shipping_city       text not null,
    shipping_province   text not null,
    shipping_postal_code text not null,
    created_at          timestamptz not null default now()
);

alter table public.order_customer_details enable row level security;
