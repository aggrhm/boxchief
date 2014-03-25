module Boxchief

  module Instrumentation

    def self.included(base)
      base.send :around_filter, :watch_request if base.respond_to?(:around_filter)
    end

    def watch_request
      t1 = Time.now
      begin
        yield
      rescue => exception
        t2 = Time.now
        log_request_data({time: t2-t1, error: (exception.message || "An error occurred")})
        raise exception
      else
        t2 = Time.now
        log_request_data({time: t2-t1})
      end
    end

    def log_request_data(data)
      data[:time] = data[:time] * 1000
      data[:controller] = params[:controller]
      data[:action] = params[:action]
      Rails.logger.info "REQUESTDATA: #{data.to_json}"
    end

    
  end

end
