require 'spec_helper'

describe 'tweets capped collection' do

  CAPPED_COLLECTIONS = HashWithIndifferentAccess.new(YAML::load_file(File.join(Rails.root, 'config', 'capped_collections.yml')))[Rails.env]

  CAP_MAX = CAPPED_COLLECTIONS[:tweets]
  NR_TIMES = CAP_MAX * 10

  def create_document idx
    Tweet.create(	
      native_id: idx.to_s,
      text: "status " << idx.to_s,
      coordinates: [ idx % 180, idx % 90 ]
    )
  end

  def last_document
    Tweet.desc(:native_id).limit(1).first	
  end

  def all_documents
    Tweet.desc(:native_id).all	
  end

  it "should have exactly #{CAP_MAX} documents" do
    (nr_docs = NR_TIMES).times do |idx|
      create_document idx
    end
    Tweet.all.size().should eq(CAP_MAX)
  end

  it "should have the latest #{CAP_MAX} documents inserted" do
    (nr_docs = NR_TIMES).times do |idx|
      create_document idx
    end
    all_documents.each_with_index do |tweet, idx|
      tweet.native_id.should eq((nr_docs-idx-1).to_s)
    end
  end

end