# frozen_string_literal: true

require 'roda'
require 'slim'
require 'slim/include'
require 'json'

module LightofDay
  # Web App
  class App < Roda
    plugin :render, engine: 'slim', views: 'app/presentation/views_html'
    plugin :assets, path: 'app/presentation/assets', css: 'style.css', js: 'main.js'
    plugin :common_logger, $stderr
    plugin :halt
    plugin :flash
    plugin :all_verbs
    plugin :status_handler

    # use Rack::MethodOverride
    status_handler(404) do
      view('404')
    end

    route do |routing|
      routing.assets # load CSS
      response['Content-Type'] = 'text/html; charset=utf-8'

      topics_mapper = Service::ListTopics.new
      topics_result = topics_mapper.call('normal')
      if topics_result.failure?
        flash[:error] = topics_result.failure
        view_topic = []
      else
        topics_result = topics_result.value!
        view_topic = Views::TopicList.new(topics_result)
      end

      # GET /
      routing.root do
        view 'picktopic', locals: { topics: view_topic }
      end

      # GET /list_topics/{sort_by}
      routing.on 'list_topics', String do |sort_by|
        routing.get do
          topics_result = topics_mapper.call(sort_by)
          if topics_result.failure?
            flash[:error] = topics_result.failure
            view_topic = []
          else
            topics_result = topics_result.value!
            view_topic = Views::TopicList.new(topics_result)
          end
          view 'picktopic', locals: { topics: view_topic }
        end
      end

      routing.on 'favorite-list' do
        routing.is do
          session[:watching] ||= []
          # Load previously viewed Views
          result = Service::ListFavorite.new.call(session[:watching])
          if result.failure?
            flash[:error] = result.failure
            view_favorite_list = []
          else
            favorite_list = result.value!
            flash.now[:error] = 'Make some collections to get started' if favorite_list.none?

            session[:watching] = favorite_list.map(&:origin_id)
            view_favorite_list = Views::FavoritecList.new(favorite_list)
          end
          view 'favoritelist', locals: { favoriteList: view_favorite_list }
        end
      end

      routing.on 'light-of-day' do
        routing.is do
          # POST /light-of-day/
          routing.post do
            topic_id = routing.params['topic_id']

            slug = topics_mapper.find_slug(topic_id)
            if slug.failure?
              flash[:error] = slug.failure
              routing.redirect '/'
            end
            slug = slug.value!
            routing.redirect "light-of-day/topic/#{slug}"
          end
        end

        routing.on 'topic', String, String, String do |topic_slug, rest_time, work_time|
          # GET /light-of-day/topic/{topic}
          routing.get do
            # puts 'hhhlo'
            Service::StoreFocus.new.call(work_time, rest_time)
            topic_data = topics_mapper.find_topic(topic_slug)
            topic_data = topic_data.value!
            view_data = Service::FindLightofDay.new.call(topic_data)
            # puts rest_time
            # puts work_time
            puts view_data.failure?
            if view_data.failure?
              flash[:error] = view_data.failure
              view_lightofday = []
            else
              view_data = view_data.value!
              view_lightofday = Views::LightofDay.new(view_data)
            end

            view 'view', locals: { view: view_lightofday, is_saved: false }
          end
        end

        routing.on 'topic', String do |topic_slug|
          # GET /light-of-day/topic/{topic}
          routing.get do
            topic_data = topics_mapper.find_topic(topic_slug)
            topic_data = topic_data.value!
            view_data = Service::FindLightofDay.new.call(topic_data)

            if view_data.failure?
              flash[:error] = view_data.failure
              view_lightofday = []
            else
              view_data = view_data.value!
              view_lightofday = Views::LightofDay.new(view_data)
            end

            view 'view', locals: { view: view_lightofday, is_saved: false }
          end
        end

        routing.on 'favorite' do
          routing.is do
            # POST /light-of-day/favorite/
            routing.post do
              view_record = Service::ParseLightofday.new.call(routing.params['favorite']).value!
              session[:watching] ||= []
              session[:watching].insert(0, view_record.origin_id).uniq!

              # store lightofday to DB
              lightofday_made = Service::StoreLightofDay.new.call(view_record)
              flash[:error] = lightofday_made.failure if lightofday_made.failure?

              view_id = routing.params['view_data']
              flash[:notice] = 'Add successfully to your favorite !'
              routing.redirect "favorite/#{view_id}"
            end
          end
          routing.on String, String, String do |view_id, rest_time, work_time|
            # GET /light-of-day/favorite/{view_id}
            routing.get do
              Service::StoreFocus.new.call(work_time, rest_time)
              lightofday_get = Service::GetLightofDay.new.call(view_id)

              if lightofday_get.failure?
                flash[:error] = lightofday_get.failure
              else
                lightofday_data = lightofday_get.value!
                flash.now[:error] = 'Data not found' if lightofday_get.nil?
              end

              view_lightofday = Views::LightofDay.new(lightofday_data)
              view 'view', locals: { view: view_lightofday, is_saved: true }
            end
          end

          routing.on String do |view_id|
            # Delete /light-of-day/favorite/{view_id}

            routing.delete do
              origin_id = view_id.to_s
              session[:watching].delete(origin_id)
              routing.redirect '/favorite-list'
            end
            # GET /light-of-day/favorite/{view_id}
            routing.get do
              lightofday_get = Service::GetLightofDay.new.call(view_id)

              if lightofday_get.failure?
                flash[:error] = lightofday_get.failure
              else
                lightofday_data = lightofday_get.value!
                flash.now[:error] = 'Data not found' if lightofday_get.nil?
              end

              view_lightofday = Views::LightofDay.new(lightofday_data)
              view 'view', locals: { view: view_lightofday, is_saved: true }
            end
          end

          # routing.on String do |view_id, _minutes|
          #   # Delete /light-of-day/favorite/{view_id}

          #   routing.delete do
          #     origin_id = view_id.to_s
          #     session[:watching].delete(origin_id)
          #     routing.redirect '/favorite-list'
          #   end
          #   # GET /light-of-day/favorite/{view_id}
          #   routing.get do
          #     lightofday_get = Service::GetLightofDay.new.call(view_id)

          #     if lightofday_get.failure?
          #       flash[:error] = lightofday_get.failure
          #     else
          #       lightofday_data = lightofday_get.value!
          #       flash.now[:error] = 'Data not found' if lightofday_get.nil?
          #     end

          #     view_lightofday = Views::LightofDay.new(lightofday_data)
          #     view 'view', locals: { view: view_lightofday, is_saved: true }
          #   end
          # end
        end
      end

      routing.on 'focus' do
        # focus_data = Service::ListFocus.new.call
        focus_data = Service::AnalyzeFocus.new.call
        if focus_data.failure?
          flash[:error] = focus_data.failure
          focus_data = []
        else
          focus_data = focus_data.value!
        end
        view 'focus', locals: { focus_data: }
      end
    end
  end
end
