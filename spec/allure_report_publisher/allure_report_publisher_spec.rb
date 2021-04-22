# frozen_string_literal: true

RSpec.describe Allure::Publisher do
  it "has a version number" do
    expect(Allure::Publisher::VERSION).not_to be nil
  end
end
