require_relative '../../spec_helper'

describe Cronofy::Client do
  before(:all) do
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:token) { 'token_123' }
  let(:base_request_headers) do
    {
      "Authorization" => "Bearer #{token}",
      "User-Agent" => "Cronofy Ruby #{::Cronofy::VERSION}",
    }
  end

  let(:json_request_headers) do
    base_request_headers.merge("Content-Type" => "application/json; charset=utf-8")
  end

  let(:request_headers) do
    base_request_headers
  end

  let(:request_body) { nil }

  let(:client) do
    Cronofy::Client.new(
      client_id: 'client_id_123',
      client_secret: 'client_secret_456',
      access_token: token,
      refresh_token: 'refresh_token_456',
    )
  end

  let(:correct_response_headers) do
    { 'Content-Type' => 'application/json; charset=utf-8' }
  end

  shared_examples 'a Cronofy request with mapped return value' do
    it 'returns the correct response when no error' do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: correct_response_code,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)

      expect(subject).to eq correct_mapped_result
    end
  end

  shared_examples 'a Cronofy request' do
    it "doesn't raise an error when response is correct" do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: correct_response_code,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)

      expect{ subject }.not_to raise_error
    end

    it 'raises AuthenticationFailureError on 401s' do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: 401,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)
      expect{ subject }.to raise_error(Cronofy::AuthenticationFailureError)
    end

    it 'raises AuthorizationFailureError on 403s' do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: 403,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)
      expect{ subject }.to raise_error(Cronofy::AuthorizationFailureError)
    end

    it 'raises NotFoundError on 404s' do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: 404,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)
      expect{ subject }.to raise_error(::Cronofy::NotFoundError)
    end

    it 'raises InvalidRequestError on 422s' do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: 422,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)
      expect{ subject }.to raise_error(::Cronofy::InvalidRequestError)
    end

    it 'raises AuthenticationFailureError on 401s' do
      stub_request(method, request_url)
        .with(headers: request_headers,
              body: request_body)
        .to_return(status: 429,
                   headers: correct_response_headers,
                   body: correct_response_body.to_json)
      expect{ subject }.to raise_error(::Cronofy::TooManyRequestsError)
    end
  end

  describe '#list_calendars' do
    let(:request_url) { 'https://api.cronofy.com/v1/calendars' }
    let(:method) { :get }
    let(:correct_response_code) { 200 }
    let(:correct_response_body) do
      {
        "calendars" => [
                        {
                          "provider_name" => "google",
                          "profile_name" => "example@cronofy.com",
                          "calendar_id" => "cal_n23kjnwrw2_jsdfjksn234",
                          "calendar_name" => "Home",
                          "calendar_readonly" => false,
                          "calendar_deleted" => false
                        },
                        {
                          "provider_name" => "google",
                          "profile_name" => "example@cronofy.com",
                          "calendar_id" => "cal_n23kjnwrw2_n1k323nkj23",
                          "calendar_name" => "Work",
                          "calendar_readonly" => true,
                          "calendar_deleted" => true
                        },
                        {
                          "provider_name" => "apple",
                          "profile_name" => "example@cronofy.com",
                          "calendar_id" => "cal_n23kjnwrw2_3nkj23wejk1",
                          "calendar_name" => "Bank Holidays",
                          "calendar_readonly" => true,
                          "calendar_deleted" => false
                        }
                       ]
      }
    end

    let(:correct_mapped_result) do
      correct_response_body["calendars"].map { |cal| Cronofy::Calendar.new(cal) }
    end

    subject { client.list_calendars }

    it_behaves_like 'a Cronofy request'
    it_behaves_like 'a Cronofy request with mapped return value'
  end

  describe 'Events' do
    describe '#create_or_update_event' do
      let(:calendar_id) { 'calendar_id_123'}
      let(:request_url) { "https://api.cronofy.com/v1/calendars/#{calendar_id}/events" }
      let(:method) { :post }
      let(:request_headers) { json_request_headers }
      let(:event) do
        {
          :event_id => "qTtZdczOccgaPncGJaCiLg",
          :summary => "Board meeting",
          :description => "Discuss plans for the next quarter.",
          :start => start_datetime,
          :end => end_datetime,
          :location => {
            :description => "Board room"
          }
        }
      end
      let(:request_body) do
        hash_including(:event_id => "qTtZdczOccgaPncGJaCiLg",
                       :summary => "Board meeting",
                       :description => "Discuss plans for the next quarter.",
                       :start => encoded_start_datetime,
                       :end => encoded_end_datetime,
                       :location => {
                         :description => "Board room"
                       })
      end
      let(:correct_response_code) { 202 }
      let(:correct_response_body) { nil }

      subject { client.create_or_update_event(calendar_id, event) }

      context 'when start/end are Times' do
        let(:start_datetime) { Time.utc(2014, 8, 5, 15, 30, 0) }
        let(:end_datetime) { Time.utc(2014, 8, 5, 17, 0, 0) }
        let(:encoded_start_datetime) { "2014-08-05T15:30:00Z" }
        let(:encoded_end_datetime) { "2014-08-05T17:00:00Z" }

        it_behaves_like 'a Cronofy request'
      end

      context 'when start/end are complex times' do
        let(:start_datetime) do
          {
            :time => Time.utc(2014, 8, 5, 15, 30, 0),
            :tzid => "Europe/London",
          }
        end
        let(:end_datetime) do
          {
            :time => Time.utc(2014, 8, 5, 17, 0, 0),
            :tzid => "America/Los_Angeles",
          }
        end
        let(:encoded_start_datetime) do
          {
            :time => "2014-08-05T15:30:00Z",
            :tzid => "Europe/London",
          }
        end
        let(:encoded_end_datetime) do
          {
            :time => "2014-08-05T17:00:00Z",
            :tzid => "America/Los_Angeles",
          }
        end

        it_behaves_like 'a Cronofy request'
      end
    end

    describe '#read_events' do
      before do
        stub_request(method, request_url)
          .with(headers: request_headers,
                body: request_body)
          .to_return(status: correct_response_code,
                     headers: correct_response_headers,
                     body: correct_response_body.to_json)

        stub_request(:get, next_page_url)
          .with(headers: request_headers)
          .to_return(status: correct_response_code,
            headers: correct_response_headers,
            body: next_page_body.to_json)
      end


      let(:request_url_prefix) { 'https://api.cronofy.com/v1/events' }
      let(:method) { :get }
      let(:correct_response_code) { 200 }
      let(:next_page_url) do
        "https://next.page.com/08a07b034306679e"
      end

      let(:params) { Hash.new }
      let(:request_url) { request_url_prefix + "?tzid=Etc/UTC" }

      let(:correct_response_body) do
        {
          'pages' => {
            'current' => 1,
            'total' => 2,
            'next_page' => next_page_url
          },
          'events' => [
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'event_uid' => 'evt_external_54008b1a4a41730f8d5c6037',
                         'summary' => 'Company Retreat',
                         'description' => '',
                         'start' => '2014-09-06',
                         'end' => '2014-09-08',
                         'deleted' => false
                       },
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'event_uid' => 'evt_external_54008b1a4a41730f8d5c6038',
                         'summary' => 'Dinner with Laura',
                         'description' => '',
                         'start' => '2014-09-13T19:00:00Z',
                         'end' => '2014-09-13T21:00:00Z',
                         'deleted' => false,
                         'location' => {
                           'description' => 'Pizzeria'
                         }
                       }
                      ]
        }
      end

      let(:next_page_body) do
        {
          'pages' => {
            'current' => 2,
            'total' => 2,
          },
          'events' => [
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'event_uid' => 'evt_external_54008b1a4a4173023402934d',
                         'summary' => 'Company Retreat Extended',
                         'description' => '',
                         'start' => '2014-09-06',
                         'end' => '2014-09-08',
                         'deleted' => false
                       },
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'event_uid' => 'evt_external_54008b1a4a41198273921312',
                         'summary' => 'Dinner with Paul',
                         'description' => '',
                         'start' => '2014-09-13T19:00:00Z',
                         'end' => '2014-09-13T21:00:00Z',
                         'deleted' => false,
                         'location' => {
                           'description' => 'Cafe'
                         }
                       }
                      ]
        }
      end

      let(:correct_mapped_result) do
        first_page_events = correct_response_body['events'].map { |event| Cronofy::Event.new(event) }
        second_page_events = next_page_body['events'].map { |event| Cronofy::Event.new(event) }

        first_page_events + second_page_events
      end

      subject do
        # By default force evaluation
        client.read_events(params).to_a
      end

      context 'when all params are passed' do
        let(:params) do
          {
            from: Time.new(2014, 9, 1, 0, 0, 1, '+00:00'),
            to: Time.new(2014, 10, 1, 0, 0, 1, '+00:00'),
            tzid: 'Etc/UTC',
            include_deleted: false,
            include_moved: true,
            last_modified: Time.new(2014, 8, 1, 0, 0, 1, '+00:00')
          }
        end
        let(:request_url) do
          "#{request_url_prefix}?from=2014-09-01T00:00:01Z" \
          "&to=2014-10-01T00:00:01Z&tzid=Etc/UTC&include_deleted=false" \
          "&include_moved=true&last_modified=2014-08-01T00:00:01Z"
        end

        it_behaves_like 'a Cronofy request'
        it_behaves_like 'a Cronofy request with mapped return value'
      end

      context 'when some params are passed' do
        let(:params) do
          {
            from: Time.new(2014, 9, 1, 0, 0, 1, '+00:00'),
            include_deleted: false,
          }
        end
        let(:request_url) do
          "#{request_url_prefix}?from=2014-09-01T00:00:01Z" \
          "&tzid=Etc/UTC&include_deleted=false"
        end

        it_behaves_like 'a Cronofy request'
        it_behaves_like 'a Cronofy request with mapped return value'
      end

      context "when unknown flags are passed" do
        let(:params) do
          {
            unknown_bool: true,
            unknown_number: 5,
            unknown_string: "foo-bar-baz",
          }
        end

        let(:request_url) do
          "#{request_url_prefix}?tzid=Etc/UTC" \
          "&unknown_bool=true" \
          "&unknown_number=5" \
          "&unknown_string=foo-bar-baz"
        end

        it_behaves_like 'a Cronofy request'
        it_behaves_like 'a Cronofy request with mapped return value'
      end

      context "next page not found" do
        before do
          stub_request(:get, next_page_url)
            .with(headers: request_headers)
            .to_return(status: 404,
              headers: correct_response_headers)
        end

        it "raises an error" do
          expect{ subject }.to raise_error(::Cronofy::NotFoundError)
        end
      end

      context "only first event" do
        before do
          # Ensure an error if second page is requested
          stub_request(:get, next_page_url)
            .with(headers: request_headers)
            .to_return(status: 404,
              headers: correct_response_headers)
        end

        let(:first_event) do
          Cronofy::Event.new(correct_response_body["events"].first)
        end

        subject do
          client.read_events(params).first
        end

        it "returns the first event from the first page" do
          expect(subject).to eq(first_event)
        end
      end

      context "without calling #to_a to force full evaluation" do
        subject { client.read_events(params) }

        it_behaves_like 'a Cronofy request'

        # We expect it to behave like a Cronofy request as the first page is
        # requested eagerly so that the majority of errors will happen inline
        # rather than lazily happening wherever the iterator may have been
        # passed.
      end
    end

    describe '#delete_event' do
      let(:calendar_id) { 'calendar_id_123'}
      let(:request_url) { "https://api.cronofy.com/v1/calendars/#{calendar_id}/events" }
      let(:event_id) { 'event_id_456' }
      let(:method) { :delete }
      let(:request_headers) { json_request_headers }
      let(:request_body) { { :event_id => event_id } }
      let(:correct_response_code) { 202 }
      let(:correct_response_body) { nil }

      subject { client.delete_event(calendar_id, event_id) }

      it_behaves_like 'a Cronofy request'
    end

    describe '#delete_all_events' do
      let(:request_url) { "https://api.cronofy.com/v1/events" }
      let(:method) { :delete }
      let(:request_headers) { json_request_headers }
      let(:request_body) { { :all_events => true } }
      let(:correct_response_code) { 202 }
      let(:correct_response_body) { nil }

      subject { client.delete_all_events }

      it_behaves_like 'a Cronofy request'
    end
  end

  describe 'Channels' do
    let(:request_url) { 'https://api.cronofy.com/v1/channels' }

    describe '#create_channel' do
      let(:method) { :post }
      let(:callback_url) { 'http://call.back/url' }
      let(:request_headers) { json_request_headers }
      let(:request_body) { hash_including(:callback_url => callback_url) }

      let(:correct_response_code) { 200 }
      let(:correct_response_body) do
        {
          'channel' => {
            'channel_id' => 'channel_id_123',
            'callback_url' => ENV['CALLBACK_URL'],
            'filters' => {}
          }
        }
      end

      let(:correct_mapped_result) do
        Cronofy::Channel.new(correct_response_body["channel"])
      end

      subject { client.create_channel(callback_url) }

      it_behaves_like 'a Cronofy request'
      it_behaves_like 'a Cronofy request with mapped return value'
    end

    describe '#list_channels' do
      let(:method) { :get }

      let(:correct_response_code) { 200 }
      let(:correct_response_body) do
        {
          'channels' => [
            {
              'channel_id' => 'channel_id_123',
              'callback_url' => 'http://call.back/url',
              'filters' => {}
            },
            {
              'channel_id' => 'channel_id_456',
              'callback_url' => 'http://call.back/url2',
              'filters' => {}
            }
          ]
        }
      end

      let(:correct_mapped_result) do
        correct_response_body["channels"].map { |ch| Cronofy::Channel.new(ch) }
      end

      subject { client.list_channels }

      it_behaves_like 'a Cronofy request'
      it_behaves_like 'a Cronofy request with mapped return value'
    end

    describe '#close_channel' do
      let(:channel_id) { "chn_1234567890" }
      let(:method) { :delete }
      let(:request_url) { "https://api.cronofy.com/v1/channels/#{channel_id}" }

      let(:correct_response_code) { 202 }
      let(:correct_response_body) { nil }

      subject { client.close_channel(channel_id) }

      it_behaves_like 'a Cronofy request'
    end
  end

  describe "Account" do
    let(:request_url) { "https://api.cronofy.com/v1/account" }

    describe "#account" do
      let(:method) { :get }

      let(:correct_response_code) { 200 }
      let(:correct_response_body) do
        {
          "account" => {
            "account_id" => "acc_id_123",
            "email" => "foo@example.com",
          }
        }
      end

      let(:correct_mapped_result) do
        Cronofy::Account.new(correct_response_body["account"])
      end

      subject { client.account }

      it_behaves_like "a Cronofy request"
      it_behaves_like "a Cronofy request with mapped return value"
    end
  end

  describe 'Profiles' do
    let(:request_url) { 'https://api.cronofy.com/v1/profiles' }

    describe '#profiles' do
      let(:method) { :get }

      let(:correct_response_code) { 200 }
      let(:correct_response_body) do
        {
          'profiles' => [
            {
              'provider_name' => 'google',
              'profile_id' => 'pro_n23kjnwrw2',
              'profile_name' => 'example@cronofy.com',
              'profile_connected' => true,
            },
            {
              'provider_name' => 'apple',
              'profile_id' => 'pro_n23kjnwrw2',
              'profile_name' => 'example@cronofy.com',
              'profile_connected' => false,
              'profile_relink_url' => 'http =>//to.cronofy.com/RaNggYu',
            },
          ]
        }
      end

      let(:correct_mapped_result) do
        correct_response_body["profiles"].map { |pro| Cronofy::Profile.new(pro) }
      end

      subject { client.list_profiles }

      it_behaves_like 'a Cronofy request'
      it_behaves_like 'a Cronofy request with mapped return value'
    end
  end

  describe 'Free busy' do
    describe '#free_busy' do
      before do
        stub_request(method, request_url)
          .with(headers: request_headers,
                body: request_body)
          .to_return(status: correct_response_code,
                     headers: correct_response_headers,
                     body: correct_response_body.to_json)

        stub_request(:get, next_page_url)
          .with(headers: request_headers)
          .to_return(status: correct_response_code,
            headers: correct_response_headers,
            body: next_page_body.to_json)
      end


      let(:request_url_prefix) { 'https://api.cronofy.com/v1/free_busy' }
      let(:method) { :get }
      let(:correct_response_code) { 200 }
      let(:next_page_url) do
        "https://next.page.com/08a07b034306679e"
      end

      let(:params) { Hash.new }
      let(:request_url) { request_url_prefix + "?tzid=Etc/UTC" }

      let(:correct_response_body) do
        {
          'pages' => {
            'current' => 1,
            'total' => 2,
            'next_page' => next_page_url
          },
          'free_busy' => [
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'start' => '2014-09-06',
                         'end' => '2014-09-08',
                         'free_busy_status' => 'busy',
                       },
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'start' => '2014-09-13T19:00:00Z',
                         'end' => '2014-09-13T21:00:00Z',
                         'free_busy_status' => 'tentative',
                       }
                      ]
        }
      end

      let(:next_page_body) do
        {
          'pages' => {
            'current' => 2,
            'total' => 2,
          },
          'free_busy' => [
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'start' => '2014-09-07',
                         'end' => '2014-09-09',
                         'free_busy_status' => 'busy',
                       },
                       {
                         'calendar_id' => 'cal_U9uuErStTG@EAAAB_IsAsykA2DBTWqQTf-f0kJw',
                         'start' => '2014-09-14T19:00:00Z',
                         'end' => '2014-09-14T21:00:00Z',
                         'free_busy_status' => 'tentative',
                       }
                      ]
        }
      end

      let(:correct_mapped_result) do
        first_page_items = correct_response_body['free_busy'].map { |period| Cronofy::FreeBusy.new(period) }
        second_page_items = next_page_body['free_busy'].map { |period| Cronofy::FreeBusy.new(period) }

        first_page_items + second_page_items
      end

      subject do
        # By default force evaluation
        client.free_busy(params).to_a
      end

      context 'when all params are passed' do
        let(:params) do
          {
            from: Time.new(2014, 9, 1, 0, 0, 1, '+00:00'),
            to: Time.new(2014, 10, 1, 0, 0, 1, '+00:00'),
            tzid: 'Etc/UTC',
            include_managed: true,
          }
        end
        let(:request_url) do
          "#{request_url_prefix}?from=2014-09-01T00:00:01Z" \
          "&to=2014-10-01T00:00:01Z&tzid=Etc/UTC&include_managed=true"
        end

        it_behaves_like 'a Cronofy request'
        it_behaves_like 'a Cronofy request with mapped return value'
      end

      context 'when some params are passed' do
        let(:params) do
          {
            from: Time.new(2014, 9, 1, 0, 0, 1, '+00:00'),
          }
        end
        let(:request_url) do
          "#{request_url_prefix}?from=2014-09-01T00:00:01Z" \
          "&tzid=Etc/UTC"
        end

        it_behaves_like 'a Cronofy request'
        it_behaves_like 'a Cronofy request with mapped return value'
      end

      context "when unknown flags are passed" do
        let(:params) do
          {
            unknown_bool: true,
            unknown_number: 5,
            unknown_string: "foo-bar-baz",
          }
        end

        let(:request_url) do
          "#{request_url_prefix}?tzid=Etc/UTC" \
          "&unknown_bool=true" \
          "&unknown_number=5" \
          "&unknown_string=foo-bar-baz"
        end

        it_behaves_like 'a Cronofy request'
        it_behaves_like 'a Cronofy request with mapped return value'
      end

      context "next page not found" do
        before do
          stub_request(:get, next_page_url)
            .with(headers: request_headers)
            .to_return(status: 404,
              headers: correct_response_headers)
        end

        it "raises an error" do
          expect{ subject }.to raise_error(::Cronofy::NotFoundError)
        end
      end

      context "only first period" do
        before do
          # Ensure an error if second page is requested
          stub_request(:get, next_page_url)
            .with(headers: request_headers)
            .to_return(status: 404,
              headers: correct_response_headers)
        end

        let(:first_period) do
          Cronofy::FreeBusy.new(correct_response_body["free_busy"].first)
        end

        subject do
          client.free_busy(params).first
        end

        it "returns the first period from the first page" do
          expect(subject).to eq(first_period)
        end
      end

      context "without calling #to_a to force full evaluation" do
        subject { client.free_busy(params) }

        it_behaves_like 'a Cronofy request'

        # We expect it to behave like a Cronofy request as the first page is
        # requested eagerly so that the majority of errors will happen inline
        # rather than lazily happening wherever the iterator may have been
        # passed.
      end
    end
  end
end
