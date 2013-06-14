
TWITTER_CONFIG = HashWithIndifferentAccess.new(YAML::load_file(File.join(Rails.root, 'config', 'twitter.yml')))[Rails.env]