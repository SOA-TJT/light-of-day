# frozen_string_literal: true

require_relative 'inspirations'

module LightofDay
  module Repository
    # Repository for Views
    class Views
      def self.all
        Database::Views.all.map { |db_view| rebuild_entity(db_view) }
      end

      def self.find_creator; end

      def self.find(entity)
        find_origin_id(entity.origin_id)
      end

      def self.find_origin_id(origin_id)
        db_record = Database::ViewsOrm.first(origin_id:)
        rebuild_entity(db_record)
      end

      def self.find_id(id)
        db_record = Database::ViewsOrm.first(id:)
        rebuild_entity(db_record)
      end

      def self.create(entity)
        raise 'Views has already exists' if find(entity)

        db_view = PersistView.new(entity).create_view.call
        rebuild_entity(db_view)
      end

      def rebuild_entity(db_record)
        return nil unless db_record

        Entity::View.new(
          db_record.to_hash.except(:topics).merge(
            inspiration: Inspirations.rebuild_entity(db_record.inspiration),
            topic: db_record.topics.split(',')
          )
        )
      end

      # help to upload the data to the Viewdatabase
      class PersistView
        def initialize(entity)
          @entity = entity
        end

        def create_view
          Database::ViewsOrm.create(@entity.to_attr_hash).merge(
            topic: @entity.topic.join(',')
          )
        end

        # not sure this function is required
        def call
          inspiration = Inspirations.db_create(@entity.inspiration)
          create_view.tap do |db_view|
            db_view.update(inspiration:)
          end
        end
      end
    end
  end
end