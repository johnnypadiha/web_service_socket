require_relative '../../model/equipamento'
require_relative '../../model/telemetria'

RSpec.describe Telemetria, :type => :model do
  it 'Associations' do
    association = Telemetria.reflect_on_association(:equipamentos)

    expect(association).to_not be false
  end

  it "exemple init" do
    @teste = "123"
    expect(@teste).to be_present
  end
end
