# frozen_string_literal: true

describe ::Jobs::BccPost do

  fab!(:sender) { Fabricate(:moderator) }
  fab!(:user0) { Fabricate(:user) }
  fab!(:user1) { Fabricate(:user) }

  let(:create_params) do
    HashWithIndifferentAccess.new(
      "raw" => "this is the content I want to send",
      "title" => "this is the title of the PM I want to send",
      "archetype" => Archetype.private_message,
      target_usernames: "#{user0.username},#{user1.username}"
    )
  end

  it "does nothing when disabled" do
    topic_count = Topic.count
    ::Jobs::BccPost.new.execute(user_id: sender.id, create_params: create_params)
    expect(Topic.count).to eq(topic_count)
  end

  context "when enabled" do
    before do
      SiteSetting.bcc_enabled = true
    end

    it "will send messages to each user" do
      topic_count = Topic.count
      ::Jobs::BccPost.new.execute(user_id: sender.id, create_params: create_params)
      expect(Topic.count).to eq(topic_count + 2)
    end
  end

end
