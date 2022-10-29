# frozen_string_literal: true

require 'delegate'
require 'http'
require_relative 'view'
require_relative 'topic'

module LightofDay
  # Library for Unsplash API
  class UnsplashApi
    API_VIEWDATA_ROOT = 'https://api.unsplash.com/'
    def initialize(token)
      @token = token
    end

    def view(id)
      view_response = Requset.new(API_VIEWDATA_ROOT, @token).get_unsplash_data("photos/#{id}").parse
      View.new(view_response, self)
    end

    def topics(slugs)
      slugs.map { |slug| Topic.new(Requset.new(API_VIEWDATA_ROOT, @token).get_unsplash_data("topics/#{slug}").parse) }
      # topic_data = Requset.new(UNSPLASH_PATH, @token).get_unsplash_data("topics/#{slug}").parse
      # Topic.new(topic_data)
    end

    # Get the response from the api
    class Response < SimpleDelegator
      # Error Code number for Unauthorized
      Unauthorized = Class.new(StandardError)
      # Error Code number for NotFound
      NotFound = Class.new(StandardError)

      HTTP_ERROR = {
        401 => Unauthorized,
        404 => NotFound
      }.freeze

      def successful?
        HTTP_ERROR.keys.none?(code)
      end

      def error
        HTTP_ERROR[code]
      end
    end

    # Send a request to the api
    class Requset
      def initialize(resource_root, token)
        @resource_root = resource_root
        @token = token
      end

      def get_unsplash_data(url_path)
        http_get("#{API_VIEWDATA_ROOT}#{url_path}")
      end

      def http_get(url)
        http_result = HTTP.headers(
          'Accept' => 'application/json',
          'Authorization' => "Client-ID #{@token}"
        ).get(url)
        Response.new(http_result).tap do |response|
          raise response.error unless response.successful?
        end
      end
    end

    # module Errors
    #   class NotFound < StandardError; end
    #   class Unauthorized < StandardError; end
    # end

    # HTTP_ERROR = {
    #   401 => Errors::Unauthorized,
    #   404 => Errors::NotFound
    # }.freeze

    # def initialize(token)
    #   @unsplash_token = token
    # end

    # def photo(id)
    #   unsplash_picture_url = unsplash_api_path("photos/#{id}")
    #   photo_data = call_unsplash_url(unsplash_picture_url).parse
    #   View.new(photo_data, self)
    # end

    # def topic(slug)
    #   unsplash_topic_url = unsplash_api_path("topics/#{slug}")
    #   topic_data = call_unsplash_url(unsplash_topic_url).parse
    #   Topic.new(topic_data)
    # end

    # def unsplash_api_path(path)
    #   "https://api.unsplash.com/#{path}"
    # end

    # def call_unsplash_url(url)
    #   result = HTTP.headers(
    #     'Accept' => 'application/json',
    #     'Authorization' => "Client-ID #{@unsplash_token}"
    #   ).get(url)
    #   successful?(result) ? result : raise(HTTP_ERROR[result.code])
    # end

    # def successful?(result)
    # HTTP_ERROR.keys.include?(result.code)
    # end
  end
end