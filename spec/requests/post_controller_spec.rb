# frozen_string_literal: true

require "rails_helper"

describe PostsController do
  let(:create_params) do
    {
      raw: "hello",
      title: "cool title",
      target_recipients: "evil,trout",
      archetype: Archetype.private_message,
    }
  end

  before { SiteSetting.bcc_enabled = true }

  it "is not found when anonymous" do
    post "/posts/bcc.json", params: create_params
    expect(response.code).to eq("404")
  end

  it "is not found when staff" do
    sign_in(Fabricate(:user))
    post "/posts/bcc.json", params: create_params
    expect(response.code).to eq("404")
  end

  context "when logged in as staff" do
    fab!(:moderator)

    before { sign_in(moderator) }

    it "can report validation errors" do
      post "/posts/bcc.json", params: create_params.merge(raw: "aaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      expect(Jobs::BccPost.jobs.length).to eq(0)
      expect(response.code).to eq("422")
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns an error if there aren't two usernames at least" do
      post "/posts/bcc.json", params: create_params.merge(target_recipients: "test")
      expect(Jobs::BccPost.jobs.length).to eq(0)
      expect(response.code).to eq("422")
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns an error if it isn't a private message" do
      post "/posts/bcc.json", params: create_params.merge(archetype: Archetype.default)
      expect(Jobs::BccPost.jobs.length).to eq(0)
      expect(response.code).to eq("422")
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "succeeds" do
      post "/posts/bcc.json", params: create_params
      expect(Jobs::BccPost.jobs.length).to eq(1)
      expect(response.code).to eq("200")
      json = JSON.parse(response.body)
      expect(json["route_to"]).to be_present
      expect(json["message"]).to be_present
    end

    it "succeeds with email addresses" do
      post "/posts/bcc.json",
           params: create_params.merge(target_recipients: "evil@example.com,trout@example.com")
      expect(Jobs::BccPost.jobs.length).to eq(1)
      expect(response.code).to eq("200")
      json = JSON.parse(response.body)
      expect(json["route_to"]).to be_present
      expect(json["message"]).to be_present
    end

    describe "xxxxx" do
      before do
        @group = Fabricate(:group, messageable_level: Group::ALIAS_LEVELS[:everyone])
        @user0 = Fabricate(:user)
        @user1 = Fabricate(:user)
        @user2 = Fabricate(:user)

        GroupUser.create(group: @group, user: moderator)
        GroupUser.create(group: @group, user: @user0)
        GroupUser.create(group: @group, user: @user1)
      end

      it "expands groups to users" do
        post "/posts/bcc.json",
             params: create_params.merge(target_recipients: "#{@group.name},#{@user2.username}")

        expect(response.code).to eq("200")
        job = Jobs::BccPost.jobs[0]
        expect(job).to be_present
        usernames = job["args"].first["targets"]
        expect(usernames).to match_array([@user0.username, @user1.username, @user2.username])
      end

      it "expects group names to be downcase" do
        post "/posts/bcc.json", params: create_params.merge(target_recipients: @group.name.upcase)

        expect(response.code).to eq("200")
        job = Jobs::BccPost.jobs[0]
        expect(job).to be_present
        usernames = job["args"].first["targets"]
        expect(usernames).to match_array([@user0.username, @user1.username])
      end
    end

    describe "batching jobs" do
      before do
        @group = Fabricate(:group, messageable_level: Group::ALIAS_LEVELS[:everyone])
        i = 0
        while i < DiscourseBCC::BATCH_SIZE + 5
          user = Fabricate(:user)
          GroupUser.create(group: @group, user: user)
          i += 1
        end
      end

      it "batches users based on batch size" do
        post "/posts/bcc.json", params: create_params.merge(target_recipients: "#{@group.name}")

        expect(response.code).to eq("200")
        job_batch_1 = Jobs::BccPost.jobs[0]
        expect(job_batch_1).to be_present
        job_batch_2 = Jobs::BccPost.jobs[1]
        expect(job_batch_2).to be_present
        usernames_batch_1 = job_batch_1["args"].first["targets"]
        usernames_batch_2 = job_batch_2["args"].first["targets"]
        create_params = job_batch_2["args"].first["create_params"]
        expect(create_params.key?("target_group_names")).to eq(false)
        expect(create_params.key?("target_users")).to eq(false)
        expect(create_params.key?("target_emails")).to eq(false)
        expect(usernames_batch_1.size).to eq(DiscourseBCC::BATCH_SIZE)
        expect(usernames_batch_2.size).to eq(5)
      end
    end
  end
end
