-- Read-only examples. Restore schema.sql and load demo_data.sql first.

-- 1. Events with their organizers (JOIN).
SELECT e.event_id, e.name AS event_name, e.date_start, e.date_end,
       o.name AS organizer_name
FROM public.event AS e
JOIN public.organizer AS o ON o.organizer_id = e.organizer_id
ORDER BY e.date_start, e.event_id;

-- 2. Ticket counts and revenue, including events with no sales (view + COALESCE).
SELECT event_id, event_name, total_tickets,
       COALESCE(total_revenue, 0) AS total_revenue,
       COALESCE(avg_price, 0) AS avg_price
FROM public.event_ticket_stats
ORDER BY total_revenue DESC, event_id;

-- 3. Ticket purchase history (three-table JOIN).
SELECT u.name AS buyer, e.name AS event_name, t.ticket_id,
       t.price, t.purchase_date
FROM public.ticket AS t
JOIN public."User" AS u ON u.user_id = t.user_id
JOIN public.event AS e ON e.event_id = t.event_id
ORDER BY t.purchase_date DESC, t.ticket_id;

-- 4. Users with more than one ticket (GROUP BY + HAVING).
SELECT u.user_id, u.name, COUNT(t.ticket_id) AS tickets_purchased,
       SUM(t.price) AS total_spent
FROM public."User" AS u
JOIN public.ticket AS t ON t.user_id = u.user_id
GROUP BY u.user_id, u.name
HAVING COUNT(t.ticket_id) > 1
ORDER BY total_spent DESC, u.user_id;

-- 5. Events with no ticket purchases (correlated NOT EXISTS).
SELECT e.event_id, e.name, e.date_start
FROM public.event AS e
WHERE NOT EXISTS (
    SELECT 1 FROM public.ticket AS t WHERE t.event_id = e.event_id
)
ORDER BY e.date_start, e.event_id;

-- 6. Rank events by revenue (CTE + window function).
WITH revenue AS (
    SELECT event_id, event_name, COALESCE(total_revenue, 0) AS revenue
    FROM public.event_ticket_stats
)
SELECT event_id, event_name, revenue,
       DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM revenue
ORDER BY revenue_rank, event_id;

-- 7. Sponsorship report (materialized view; refreshed by demo_data.sql).
SELECT event_name, sponsor_name, level_of_sponsorship
FROM public.event_sponsors_info
ORDER BY event_name, sponsor_name;

-- 8. Generate XML with nested sponsor lists (XML functions + subquery).
SELECT XMLROOT(
    XMLELEMENT(NAME events,
        XMLAGG(
            XMLELEMENT(NAME event,
                XMLATTRIBUTES(e.event_id AS id),
                XMLFOREST(e.name AS name, e.date_start AS date_start),
                XMLELEMENT(NAME organizer,
                    XMLATTRIBUTES(o.organizer_id AS id),
                    XMLFOREST(o.name AS name)),
                XMLELEMENT(NAME sponsors,
                    (SELECT XMLAGG(
                        XMLELEMENT(NAME sponsor,
                            XMLATTRIBUTES(s.sponsor_id AS id,
                                          es.level_of_sponsorship AS level),
                            XMLFOREST(s.name AS name))
                        ORDER BY s.sponsor_id)
                     FROM public.event_sponsor AS es
                     JOIN public.sponsor AS s ON s.sponsor_id = es.sponsor_id
                     WHERE es.event_id = e.event_id))
            ) ORDER BY e.event_id)
    ), VERSION '1.0'
) AS events_xml
FROM public.event AS e
JOIN public.organizer AS o ON o.organizer_id = e.organizer_id;
