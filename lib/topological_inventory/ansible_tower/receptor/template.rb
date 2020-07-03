module TopologicalInventory::AnsibleTower
  module Receptor
    class Template < ApiObject
      # Job (Workflow Job) Template ordering => POST request to Tower
      def launch(post_data)
        path = File.join(endpoint, id.to_s, '/')

        response = send_request(:post, path, post_data)
        parse_response(response)

        job = JSON.parse(response)

        api.jobs.find(job['job'])
      end

      # URI + String removes URI path if String starts with '/'
      # This technique is used by Faraday client
      def survey_spec
        spec_url = related['survey_spec']
        return nil unless spec_url

        api.get(spec_url).body
      rescue AnsibleTowerClient::UnlicensedFeatureError => e
        logger.error("UnlicensedFeatureError: GET survey for Template #{id}. #{e.backtrace.join('\n')}")
      end
    end
  end
end
