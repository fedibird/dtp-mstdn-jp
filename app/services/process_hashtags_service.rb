# frozen_string_literal: true

class ProcessHashtagsService < BaseService
  def call(status, tags = [])
    if status.local?
      tags = Extractor.extract_hashtags(status.text)

      if Rails.configuration.x.default_hashtag.present? && tags.empty? && status.visibility == 'public' then
        tags << Rails.configuration.x.default_hashtag
        status.update(text: "#{status.text} ##{Rails.configuration.x.default_hashtag}")
      end
    end
    records = []

    Tag.find_or_create_by_names(tags) do |tag|
      status.tags << tag
      records << tag

      TrendingTags.record_use!(tag, status.account, status.created_at) if status.public_visibility?
    end

    return unless status.distributable?

    status.account.featured_tags.where(tag_id: records.map(&:id)).each do |featured_tag|
      featured_tag.increment(status.created_at)
    end
  end
end
