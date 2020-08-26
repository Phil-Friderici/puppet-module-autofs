require 'spec_helper'

describe 'autofs' do
  describe 'mountmap' do
    context 'defines /home' do
      let :params do
        {
          maps: {
            'home' => {
              'mountpoint' => 'home',
              'mounts'     => ['server:/home/a', 'server:/home/b', 'server:/home/c'],
            },
          },
        }
      end

      it 'contains auto.home' do
        is_expected.to contain_file('mountmap_home').with_path('/etc/auto.home')
      end
      it 'has correct permissions' do
        is_expected.to contain_file('mountmap_home').with(
          'owner' => 'root',
          'group' => 'root',
          'mode'  => '0644',
        )
      end

      it 'auto.home should be referenced in auto.master' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/home \/etc\/auto.home$})
      end

      it 'auto.home should contain the map' do
        is_expected.to contain_file('mountmap_home').with_content(%r{^server:\/home\/a$})
        is_expected.to contain_file('mountmap_home').with_content(%r{^server:\/home\/b$})
        is_expected.to contain_file('mountmap_home').with_content(%r{^server:\/home\/c$})
      end
    end
    context 'defines /home as NIS map' do
      let :params do
        {
          maps: {
            'auto.home' => {
              'mountpoint' => 'home',
              'maptype'    => 'yp',
            },
          },
        }
      end

      it 'contains auto.master definition' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/home yp auto.home$})
      end
    end
    context 'have a +auto.master as default' do
      let :params do
        {
          maps: {
            'auto.home' => {
              'mountpoint' => 'home',
              'maptype'    => 'yp',
            },
          },
        }
      end

      it 'contains NIS auto.master' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\+auto.master$})
      end
    end
    context 'have a custom NIS master' do
      let :params do
        {
          nis_master_name: 'auto.custommaster',
          maps: {
            'auto.home' => {
              'mountpoint' => 'home',
              'maptype'    => 'yp',
            },
          },
        }
      end

      it 'contains NIS auto.master' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\+auto.custommaster$})
      end
    end
    context 'have +auto.master disabled' do
      let :params do
        {
          use_nis_maps: 'false',
          maps: {
            'auto.home' => {
              'mountpoint' => 'home',
              'maptype'    => 'yp',
            },
          },
        }
      end

      it 'contains auto.master definition' do
        is_expected.not_to contain_file('auto.master').with_content(%r{^\s*\+auto.master$})
      end
    end
    context 'defines two mountpoints' do
      let :params do
        {
          maps: {
            'home' => {
              'mountpoint' => 'home',
              'mounts'     => ['server:/home/a', 'server:/home/b', 'server:/home/c'],
            },
            'data' => {
              'mountpoint' => 'data',
              'mounts'     => ['server:/data/a', 'server:/data/b', 'server:/data/c'],
              'options'    => '--vers=3',
            },
          },
        }
      end

      it 'contains both auto.home and auto.data' do
        is_expected.to contain_file('mountmap_home').with_path('/etc/auto.home')
        is_expected.to contain_file('mountmap_data').with_path('/etc/auto.data')
      end
      it 'auto.master should contain both files' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/home \/etc\/auto.home$})
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/data \/etc\/auto.data})
      end
      it 'auto.master should contain options for data mount' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/data \/etc\/auto.data --vers=3$})
      end

      it 'the maps should contain the corresponding data' do
        is_expected.to contain_file('mountmap_home').with_content(%r{^server:\/home\/a$})
        is_expected.to contain_file('mountmap_home').with_content(%r{^server:\/home\/b$})
        is_expected.to contain_file('mountmap_home').with_content(%r{^server:\/home\/c$})
        is_expected.to contain_file('mountmap_data').with_content(%r{^server:\/data\/a$})
        is_expected.to contain_file('mountmap_data').with_content(%r{^server:\/data\/b$})
        is_expected.to contain_file('mountmap_data').with_content(%r{^server:\/data\/c$})
      end
    end
    context 'define mountpoint with subpaths' do
      let :params do
        {
          maps: {
            'ftp' => {
              'mountpoint' => 'ftp/projects',
              'mounts'     => ['server:/ftp/a', 'server:/ftp/b', 'server:/ftp/c'],
            },
          },
        }
      end

      it 'auto.master should contain file with correct path' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/ftp\/projects \/etc\/auto.ftp$})
      end
      it 'contains auto.ftp' do
        is_expected.to contain_file('mountmap_ftp').with_path('/etc/auto.ftp')
      end
      it 'the map should contain the corresponding data' do
        is_expected.to contain_file('mountmap_ftp').with_content(%r{^server:\/ftp\/a$})
        is_expected.to contain_file('mountmap_ftp').with_content(%r{^server:\/ftp\/b$})
        is_expected.to contain_file('mountmap_ftp').with_content(%r{^server:\/ftp\/c$})
      end
    end
    context 'without defining mountpoint' do
      let :params do
        {
          maps: {
            'ftp' => {
              'mounts' => ['server:/ftp/a', 'server:/ftp/b', 'server:/ftp/c'],
            },
          },
        }
      end

      it 'auto.master should contain file with correct path' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/ftp \/etc\/auto.ftp$})
      end
      it 'contains auto.ftp' do
        is_expected.to contain_file('mountmap_ftp').with_path('/etc/auto.ftp')
      end
    end
    context 'define home as unmanaged' do
      let :params do
        {
          maps: {
            'home' => {
              'mountpoint' => 'home',
              'manage'     => false,
            },
          },
        }
      end

      it 'contains auto.home with null option' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/home -null$})
      end
    end
    context 'should not load NIS maps' do
      let :params do
        {
          maps: {
            'home' => {
              'mountpoint' => 'home',
            },
          },
          use_nis_maps: false,
        }
      end

      it 'contains auto.home' do
        is_expected.to contain_file('auto.master').with_content(%r{^\s*\/home \/etc\/auto.home$})
      end
      it 'does not contain +auto.master' do
        is_expected.not_to contain_file('auto.master').with_content(%r{^\+auto.master$})
      end
    end
  end

  describe 'use cases' do
    head = "# This file is being maintained by Puppet.\n# DO NOT EDIT\n\n"
    tail = "\n\n+auto.master\n"

    # https://github.com/kodguru/puppet-module-autofs/issues/25
    context 'issue #25 described expected behavior' do
      let(:facts) { { group: 'issue-25_from_hiera_group' } }

      it "auto.master contains correct '/proj yp auto.proj' as result" do
        is_expected.to contain_file('auto.master').with_content("#{head}/net -hosts\n\n/proj yp auto.proj#{tail}")
      end
    end

    context 'issue #25 described unexected behavior' do
      let(:facts) { { fqdn: 'issue-25.from.hiera.fqdn' } }

      it "auto.master contains wrong '/proj /etc/auto.auto.proj' as result" do
        is_expected.to contain_file('auto.master').with_content("#{head}/net -hosts\n\n/proj /etc/auto.auto.proj#{tail}")
      end
      it "map file uses wrong '/etc/auto.auto.proj' as path" do
        is_expected.to contain_file('mountmap_auto.proj').with_path('/etc/auto.auto.proj')
      end
      it "map file uses correct '/path/to/file/with/mounts' as source" do
        is_expected.to contain_file('mountmap_auto.proj').with_source('/path/to/file/with/mounts')
      end
    end

    context 'issue #25 fix using mappath to override previous declared mounts when using $maps_hiera_merge' do
      let(:facts) { { fqdn: 'issue-25-fix.from.hiera.fqdn', group: 'issue-25_from_hiera_group' } }
      let(:params) { { maps_hiera_merge: true } }

      it "auto.master contains correct '/proj /etc/auto.proj' as result" do
        is_expected.to contain_file('auto.master').with_content("#{head}/net -hosts\n\n/proj /etc/auto.proj#{tail}")
      end
      it "map file uses correct '/etc/auto.proj' as path" do
        is_expected.to contain_file('mountmap_auto.proj').with_path('/etc/auto.proj')
      end
      it "map file uses correct '/path/to/file/with/mounts' as source" do
        is_expected.to contain_file('mountmap_auto.proj').with_source('/path/to/file/with/mounts')
      end
    end
  end
end
