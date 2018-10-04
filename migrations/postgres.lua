return {
  {
    name = "2015-08-03-132400_init_sessionlimiting",
    up = [[
      CREATE TABLE IF NOT EXISTS sessionlimiting_metrics(
        api_id uuid,
        identifier text,
        period text,
        period_date timestamp without time zone,
        value integer,
        PRIMARY KEY (api_id, identifier, period_date, period)
      );

      CREATE OR REPLACE FUNCTION increment_session_limits(a_id uuid, i text, p text, p_date timestamp with time zone, v integer) RETURNS VOID AS $$
      BEGIN
        LOOP
          UPDATE sessionlimiting_metrics SET value = value + v WHERE api_id = a_id AND identifier = i AND period = p AND period_date = p_date;
          IF found then
            RETURN;
          END IF;

          BEGIN
            INSERT INTO sessionlimiting_metrics(api_id, period, period_date, identifier, value) VALUES(a_id, p, p_date, i, v);
            RETURN;
          EXCEPTION WHEN unique_violation THEN

          END;
        END LOOP;
      END;
      $$ LANGUAGE 'plpgsql';
    ]],
    down = [[
      DROP TABLE sessionlimiting_metrics;
    ]]
  },
  {
    name = "2016-07-25-471385_sessionlimiting_policies",
    up = function(_, _, dao)
      local rows, err = dao.plugins:find_all {name = "session-limiting"}
      if err then
        return err
      end

      for i = 1, #rows do
        local session_limiting = rows[i]

        -- Delete the old one to avoid conflicts when inserting the new one
        local _, err = dao.plugins:delete(session_limiting)
        if err then
          return err
        end

        local _, err = dao.plugins:insert {
          name = "session-limiting",
          api_id = session_limiting.api_id,
          consumer_id = session_limiting.consumer_id,
          enabled = session_limiting.enabled,
          config = {
            second = session_limiting.config.second,
            minute = session_limiting.config.minute,
            hour = session_limiting.config.hour,
            day = session_limiting.config.day,
            month = session_limiting.config.month,
            year = session_limiting.config.year,
            limit_by = "session",
            policy = "cluster",
            fault_tolerant = session_limiting.config.continue_on_error
          }
        }
        if err then
          return err
        end
      end
    end
  },
  {
    name = "2017-11-30-120000_add_route_and_service_id",
    up = [[
      ALTER TABLE sessionlimiting_metrics DROP CONSTRAINT sessionlimiting_metrics_pkey;
      ALTER TABLE sessionlimiting_metrics ALTER COLUMN api_id SET DEFAULT '00000000000000000000000000000000';
      ALTER TABLE sessionlimiting_metrics ADD COLUMN route_id uuid NOT NULL DEFAULT '00000000000000000000000000000000';
      ALTER TABLE sessionlimiting_metrics ADD COLUMN service_id uuid NOT NULL DEFAULT '00000000000000000000000000000000';
      ALTER TABLE sessionlimiting_metrics ADD PRIMARY KEY (api_id, route_id, service_id, identifier, period_date, period);

      CREATE OR REPLACE FUNCTION increment_session_limits(r_id uuid, s_id uuid, i text, p text, p_date timestamp with time zone, v integer) RETURNS VOID AS $$
      BEGIN
        LOOP
          UPDATE sessionlimiting_metrics
          SET value = value + v
          WHERE route_id = r_id
            AND service_id = s_id
            AND identifier = i
            AND period = p
            AND period_date = p_date;
          IF found then RETURN;
          END IF;

          BEGIN
            INSERT INTO sessionlimiting_metrics(route_id, service_id, period, period_date, identifier, value)
                        VALUES(r_id, s_id, p, p_date, i, v);
            RETURN;
          EXCEPTION WHEN unique_violation THEN
          END;
        END LOOP;
      END;
      $$ LANGUAGE 'plpgsql';
      CREATE OR REPLACE FUNCTION increment_session_limits_api(a_id uuid, i text, p text, p_date timestamp with time zone, v integer) RETURNS VOID AS $$
      BEGIN
        LOOP
          UPDATE sessionlimiting_metrics SET value = value + v WHERE api_id = a_id AND identifier = i AND period = p AND period_date = p_date;
          IF found then
            RETURN;
          END IF;

          BEGIN
            INSERT INTO sessionlimiting_metrics(api_id, period, period_date, identifier, value) VALUES(a_id, p, p_date, i, v);
            RETURN;
          EXCEPTION WHEN unique_violation THEN

          END;
        END LOOP;
      END;
      $$ LANGUAGE 'plpgsql';
    ]],
    down = nil,
  },
--  {
--    name = "2017-11-30-130000_remove_api_id",
--    up = [[
--      ALTER TABLE sessionlimiting_metrics DROP COLUMN api_id;
--    ]],
--    down = nil,
--  },
}
