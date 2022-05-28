set_project("restic_autobackup")

set_version("0.1.0")

add_rules("mode.debug", "mode.release")
set_defaultmode("debug")





-- add_requires("nimble::nim >=1.6.6")
add_requires("nimble::regex >=0.19.0")

if is_mode("debug") then
    add_requires("nimble::unittest2 >=0.0.3")
end



target("backup")
    set_kind("binary")
    set_default(true)
    add_files("src/*.nim")
    set_targetdir("bin")


target("test")

    on_config(function (target)
        if is_mode("release") then 
            raise("target 'test' cannot be in release mode")
        end
    end)

    set_kind("phony")
    set_default(false)

    set_options("debug")

