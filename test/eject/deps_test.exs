defmodule Eject.DepsTest do
  use Eject.ProjectCase

  alias Eject.{Deps, Manifest, Config}

  test "discover!/2 packages all mix/lib deps and catalogues which ones are required for the app" do
    config = %Config{
      base_app: :test,
      mix_module: TestProject.MixProject,
      module: TestProject.Eject.Project
    }

    manifest = Manifest.new!(config, mix_deps: [:included_mix], lib_deps: [:included_lib])
    result = Deps.discover!(config, manifest)

    # all mix/lib deps are returned in the :all key
    assert result.all.lib == [
             :always_included_lib,
             :eject,
             :excluded_lib,
             :included_lib,
             :indirectly_included_lib,
             :tweeter,
             :with_only
           ]

    assert result.all.mix == [
             :always_included_mix,
             :excluded_mix,
             :included_mix,
             :indirectly_included_mix
           ]

    # only included mix/lib deps are included in the :mix and :lib keys
    assert Map.has_key?(result.mix, :included_mix)
    assert Map.has_key?(result.mix, :always_included_mix)
    refute Map.has_key?(result.mix, :excluded_mix)
    assert Map.has_key?(result.lib, :included_lib)
    refute Map.has_key?(result.lib, :excluded_lib)
  end
end
