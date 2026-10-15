-- Synthetic demo data. Run once in a fresh database after schema.sql.
-- All names/contact details are fictional; amounts have no assigned currency.
BEGIN;
SET LOCAL search_path = public, pg_catalog;

DO $$
DECLARE
    u1 integer; u2 integer; u3 integer; u4 integer; u5 integer;
    o1 integer; o2 integer;
    e1 integer; e2 integer; e3 integer;
    s1 integer; s2 integer; s3 integer;
BEGIN
    IF EXISTS (SELECT 1 FROM public."User")
       OR EXISTS (SELECT 1 FROM public.organizer)
       OR EXISTS (SELECT 1 FROM public.event)
       OR EXISTS (SELECT 1 FROM public.sponsor)
       OR EXISTS (SELECT 1 FROM public.event_sponsor)
       OR EXISTS (SELECT 1 FROM public.ticket) THEN
        RAISE EXCEPTION 'Load demo_data.sql only into empty project tables.';
    END IF;

    INSERT INTO public."User" (name, email) VALUES ('Demo Organizer A', 'organizer.a@example.com') RETURNING user_id INTO u1;
    INSERT INTO public."User" (name, email) VALUES ('Demo Organizer B', 'organizer.b@example.com') RETURNING user_id INTO u2;
    INSERT INTO public."User" (name, email) VALUES ('Demo Attendee A', 'attendee.a@example.com') RETURNING user_id INTO u3;
    INSERT INTO public."User" (name, email) VALUES ('Demo Attendee B', 'attendee.b@example.com') RETURNING user_id INTO u4;
    INSERT INTO public."User" (name, email) VALUES ('Demo Attendee C', 'attendee.c@example.com') RETURNING user_id INTO u5;

    INSERT INTO public.organizer (name, email, user_id) VALUES ('Demo Developer Community', 'community@example.com', u1) RETURNING organizer_id INTO o1;
    INSERT INTO public.organizer (name, email, user_id) VALUES ('Demo Learning Club', 'learning@example.com', u2) RETURNING organizer_id INTO o2;

    INSERT INTO public.event (name, description, address, date_start, date_end, organizer_id)
    VALUES ('Python Community Meetup', 'A fictional meetup for Python learners.', 'Demo venue A', CURRENT_TIMESTAMP + INTERVAL '10 days', CURRENT_TIMESTAMP + INTERVAL '10 days 3 hours', o1)
    RETURNING event_id INTO e1;
    INSERT INTO public.event (name, description, address, date_start, date_end, organizer_id)
    VALUES ('SQL Practice Workshop', 'A fictional hands-on SQL workshop.', 'Demo venue B', CURRENT_TIMESTAMP + INTERVAL '15 days', CURRENT_TIMESTAMP + INTERVAL '15 days 4 hours', o2)
    RETURNING event_id INTO e2;
    INSERT INTO public.event (name, description, address, date_start, date_end, organizer_id)
    VALUES ('Open Source Evening', 'A fictional event with no ticket purchases yet.', 'Demo venue C', CURRENT_TIMESTAMP + INTERVAL '20 days', CURRENT_TIMESTAMP + INTERVAL '20 days 2 hours', o1)
    RETURNING event_id INTO e3;

    INSERT INTO public.sponsor (name, email) VALUES ('Demo Sponsor Alpha', 'alpha@example.com') RETURNING sponsor_id INTO s1;
    INSERT INTO public.sponsor (name, email) VALUES ('Demo Sponsor Beta', 'beta@example.com') RETURNING sponsor_id INTO s2;
    INSERT INTO public.sponsor (name, email) VALUES ('Demo Sponsor Gamma', 'gamma@example.com') RETURNING sponsor_id INTO s3;

    INSERT INTO public.event_sponsor (event_id, sponsor_id, level_of_sponsorship)
    VALUES (e1, s1, 'головний'), (e1, s2, 'преміальний'), (e2, s2, 'головний'), (e2, s3, 'звичайний');

    INSERT INTO public.ticket (event_id, user_id, price)
    VALUES (e1, u3, 250.00), (e1, u4, 250.00), (e1, u5, 200.00),
           (e2, u3, 300.00), (e2, u4, 300.00);
END;
$$;

REFRESH MATERIALIZED VIEW public.event_sponsors_info;
COMMIT;
