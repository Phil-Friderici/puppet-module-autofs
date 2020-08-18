require 'spec_helper'
describe 'autofs::map' do
  mountmap_header = "# This file is being maintained by Puppet.\n# DO NOT EDIT\n\n"
  let(:title) { 'example' }

  context 'with defaults for all parameters' do
    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_file('mountmap_example').only_with(
        'ensure'  => 'file',
        'path'    => '/etc/auto.example',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'content' => mountmap_header,
      )
    }
  end

  context 'with functional parameters set' do
    context 'with mounts set to valid array <[spec srv:/path/spec\, test srv:/path/test]>' do
      let(:params) { { mounts: ['spec srv:/path/spec', 'test srv:/path/test'] } }

      it {
        is_expected.to contain_file('mountmap_example').with('content' => "#{mountmap_header}spec srv:/path/spec\ntest srv:/path/test\n")
      }
    end

    context 'with mounts set to valid string <spectest server:/spec/test]>' do
      let(:params) { { mounts: ['spectest server:/spec/test'] } }

      it {
        is_expected.to contain_file('mountmap_example').with('content' => "#{mountmap_header}spectest server:/spec/test\n")
      }
    end

    context 'with file set to <puppet:///files/autofs/specific.map>' do
      let(:params) { { file: 'puppet:///files/autofs/specific.map' } }

      it {
        is_expected.to contain_file('mountmap_example').only_with(
          'ensure' => 'file',
          'path'   => '/etc/auto.example',
          'owner'  => 'root',
          'group'  => 'root',
          'mode'   => '0644',
          'source' => 'puppet:///files/autofs/specific.map',
        )
      }
    end

    context 'with mappath set to valid string </test/ing>' do
      let(:params) { { mappath: '/test/ing' } }

      it {
        is_expected.to contain_file('mountmap_example').with('path' => '/test/ing' )
      }
    end

    context 'with mapname set to valid string <testname>' do
      let(:params) { { mapname: 'testname' } }

      it {
        is_expected.to contain_file('testname')
      }
    end

  end

  context 'with non-functional parameters set' do
    # $autofs::maps is also used for auto.master template.
    # The following parameters are not used in autofs::map.
    # But they need to exist to avoid "invalid parameter options" errors.
    ['mountpoint', 'maptype', 'manage', 'options'].each do |param|
      context "with #{param} set to <unneeded>" do
        let(:params) { { :"#{param}" => 'unneeded' } }

        it {
          is_expected.to contain_file('mountmap_example').only_with(
            'ensure' => 'file',
            'path'    => '/etc/auto.example',
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0644',
            'content' => mountmap_header,
          )
        }
      end
    end
  end

  describe 'variable type and content validations' do
    # set needed custom facts and variables
    let(:title) { 'example' }

    validations = {
      'absolute_path' => {
        name:    ['mappath'],
        valid:   ['/absolute/filepath', '/absolute/directory/'],
        invalid: ['../invalid', 3, 2.42, ['array'], { 'ha' => 'sh' }, false],
        message: 'is not an absolute path', # source: stdlib:validate_absolute_path
      },
      'array / string' => {
        name:    ['mounts'],
        valid:   [['array'], 'string'],
        invalid: [{ 'ha' => 'sh' }, 3, 2.42, false],
        message: 'is not an array', # source: autofs::maps:fail
      },
      'string' => {
        name:    ['mapname'],
        valid:   ['string'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
        message: 'is not a string', # source: autofs::maps:fail
      },
      'string for file source' => {
        name:    ['file'],
        valid:   ['puppet:///test', '/test/ing', 'file:///test/ing'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
        message: 'is not a string', # source: autofs::maps:fail
      },
    }

    validations.sort.each do |type, var|
      mandatory_params = {} if mandatory_params.nil?
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid] = {} if var[:valid].nil?
        var[:invalid] = {} if var[:invalid].nil?

        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:facts) { [mandatory_facts, var[:facts]].reduce(:merge) } unless var[:facts].nil?
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid }].reduce(:merge) }

            it { is_expected.to compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid }].reduce(:merge) }

            it 'fails' do
              expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
