require 'spec_helper'
describe 'bird' do

  context 'with defaults for all parameters' do
    it { should contain_class('bird') }
  end
end
