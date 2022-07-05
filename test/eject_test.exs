defmodule EjectTest do
  use ExUnit.Case, async: true

  alias Eject.{Project, Manifest, App}

  @destination "test/support/ejected"

  defp read!(path) do
    File.read!(@destination <> "/" <> path)
  end

  test "full ejection" do
    # this is gitignored; we can eject to it without adding to the git index
    # prepare app
    project = %Project{base_app: :test_app, module: TestApp.Project, destination: @destination}
    manifest = %Manifest{lib_deps: [:included_lib], mix_deps: [:included_mix]}
    app = App.new!(project, manifest, Tweeter)

    Eject.eject(app)

    # check for files that are always ejected (read! will crash if missing)
    read!("tweeter/mix.exs")
    read!("tweeter/mix.lock")
    read!("tweeter/.gitignore")
    read!("tweeter/.formatter.exs")
    read!("tweeter/test/test_helper.exs")

    # files in {:dir, _} tuples should not be modified
    file_txt = read!("tweeter/test/support/dir/file.txt")
    assert file_txt =~ "TestApp"
    refute file_txt =~ "Tweeter"

    # lib files should be modified
    lib_file = read!("tweeter/test/support/lib/included_lib/included.ex")
    assert lib_file =~ "Tweeter"
    refute lib_file =~ "TestApp"

    # files are created from templates
    template_file = read!("tweeter/config/runtime.exs")
    assert template_file =~ "1 + 1 = 2"
    assert template_file =~ "App name is tweeter"
    assert template_file =~ "Depends on included_mix"
    refute template_file =~ "Depends on excluded_mix"

    # transformations from modify/0 are ran
    modified_file = read!("tweeter/test/support/.dotfile")
    assert modified_file =~ "[REPLACED LINE WHILE EJECTING Tweeter]"
    refute modified_file =~ "[REPLACE THIS LINE VIA modify/0]"

    # files in `preserve` option are never cleared
    # (note: TestApp.Project specifies to preserve .gitignore)
    Eject.clear_destination(app)
    read!("tweeter/.gitignore")
  end
end
