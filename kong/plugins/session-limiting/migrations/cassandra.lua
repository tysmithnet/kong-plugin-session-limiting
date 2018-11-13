return {
  {
    name = "session_limiting_cassandra0",
    up = [[
      CREATE TABLE IF NOT EXISTS sessionlimiting_metrics(
        api_id uuid,
        identifier text,
        period text,
        period_date timestamp,
        value counter,
        PRIMARY KEY ((api_id, identifier, period_date, period))
      );
    ]],
    down = [[
      DROP TABLE sessionlimiting_metrics;
    ]]
  },
  {
    name = "session_limiting_cassandra1",
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
    name = "session_limiting_cassandra2",
    up = [[
      DROP TABLE sessionlimiting_metrics;
      CREATE TABLE sessionlimiting_metrics(
        route_id uuid,
        service_id uuid,
        api_id uuid,
        identifier text,
        period text,
        period_date timestamp,
        value counter,
        PRIMARY KEY ((route_id, service_id, api_id, identifier, period_date, period))
      );
    ]],
    down = nil,
  },

}
