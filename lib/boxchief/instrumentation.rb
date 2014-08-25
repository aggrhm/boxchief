module Boxchief

  module Instrumentation

    def self.included(base)
      base.send :around_filter, :watch_request if base.respond_to?(:around_filter)
    end

    def watch_request
      ex = nil
      t1 = Time.now
      @request_profile = {
        controller: params[:controller],
        action: params[:action]
      }
      begin
        yield
      rescue => exception
        ex = exception
        @request_profile[:error] = exception.message || "An error occurred"
      ensure
        t2 = Time.now
        @request_profile[:time] = (t2-t1) * 1000
        # TODO: add queue_time field
        if h_rqs = request.headers['X-Request-Start']
          h_rqs = h_rqs.gsub(/[^\d\.]/, "").to_f
          @request_profile[:queue_time] = (t1 - Time.at(h_rqs / 1000.0)) * 1000
        end
        log_request_profile
      end
      raise ex if ex
    end

    def log_request_profile
      Rails.logger.info "REQUEST_PROFILE: #{@request_profile.to_json}"
    end
    
  end

end
