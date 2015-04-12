require 'spec_helper'
describe 'winnetdrive' do

  context 'with defaults for all parameters' do
    it { should contain_class('winnetdrive') }
  end
end
