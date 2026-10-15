-- Read-only checks for the untouched synthetic demo dataset.
-- Results are reported as PASS/FAIL rows; FAIL does not raise a SQL exception.
WITH checks(check_name, expected, actual) AS (
    SELECT 'users', 5::numeric, COUNT(*)::numeric FROM public."User"
    UNION ALL SELECT 'organizers', 2, COUNT(*) FROM public.organizer
    UNION ALL SELECT 'events', 3, COUNT(*) FROM public.event
    UNION ALL SELECT 'sponsors', 3, COUNT(*) FROM public.sponsor
    UNION ALL SELECT 'sponsorship links', 4, COUNT(*) FROM public.event_sponsor
    UNION ALL SELECT 'tickets', 5, COUNT(*) FROM public.ticket
    UNION ALL SELECT 'ticket revenue', 1300, COALESCE(SUM(price), 0) FROM public.ticket
    UNION ALL SELECT 'zero-ticket events', 1, COUNT(*) FROM public.event_ticket_stats WHERE total_tickets = 0
    UNION ALL SELECT 'materialized view rows', 4, COUNT(*) FROM public.event_sponsors_info
    UNION ALL SELECT 'public user view rows', 5, COUNT(*) FROM public.public_users
)
SELECT check_name, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS result
FROM checks
UNION ALL
SELECT 'OVERALL', NULL::numeric, NULL::numeric,
       CASE WHEN BOOL_AND(expected = actual) THEN 'PASS' ELSE 'FAIL' END
FROM checks;
