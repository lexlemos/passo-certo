CREATE OR REPLACE FUNCTION active_obstacles_in_bbox(
  min_lat double precision,
  min_lng double precision,
  max_lat double precision,
  max_lng double precision
)
RETURNS SETOF obstacles
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM obstacles
  WHERE latitude >= min_lat
    AND latitude <= max_lat
    AND longitude >= min_lng
    AND longitude <= max_lng
    AND status != 'RESOLVED';
$$;
