CREATE OR REPLACE FUNCTION
    deleteMeterPredictors(_mid integer)
  RETURNS
    boolean
  LANGUAGE plpgsql AS $$
    DECLARE
      tbl character varying;
      actable character varying;
    BEGIN
      FOR
        tbl, actable IN
          SELECT DISTINCT
            LOWER(REGEXP_REPLACE(actable_type, '(.)([A-Z])', '\1_\2', 'g')) || 's' as tbl,
            actable_type AS actable
        FROM
          meter_predictors
        LOOP
          EXECUTE '
        DELETE
          FROM
            ' || tbl || '
          WHERE
            id IN
              (
                SELECT * FROM (
                  SELECT
                      ' || tbl || '.id
                    FROM
                      ' || tbl || '
                    LEFT JOIN
                      meter_predictors
                    ON
                      meter_predictors.actable_id = ' || tbl || '.id
                    WHERE
                      meter_predictors.meter_id = ' || _mid || '
                    AND
                      meter_predictors.actable_type = ''' || actable || '''
                ) AS t
              )
          ';
        END LOOP;
      return true;
    END;
  $$;

  SELECT deleteMeterPredictors(5);

  DELETE
    FROM
  meter_predictors
    WHERE
  id = 5;