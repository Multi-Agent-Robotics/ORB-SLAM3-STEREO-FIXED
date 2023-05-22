---@diagnostic disable: undefined-global
local project_name = "DBoW2"

set_project(project_name)
add_rules("mode.debug", "mode.release")

set_policy("build.warning", true)
set_policy("build.optimization.lto", true)
set_warnings("all", "extra")

add_requires("cmake::OpenCV 4.2.0", {alias = "opencv", system = true})
-- add_requires("apt::libopencv-dev", {alias = "opencv", system = true})

target("DBoW2", function()
	set_kind("shared")
    set_languages("cxx17")
    
	add_files("DBoW2/*.cpp")
	add_files("DUtils/*.cpp")
	add_includedirs(".", { public = true })
	add_packages("opencv")
    
	-- Xmake automatically detects the flags that are supported by the compiler and linker
	-- You can use 'set_policy' to disable this automatic detection if needed.
	add_cxflags("-O3", "-march=native")
	add_ldflags("-O3", "-march=native")
    
	-- Xmake handles installation directories for targets.
	-- However, you may need to adjust the directories according to your needs.
	after_install(function(target)
		os.cp("DBoW2/*.h", path.join(target:installdir(), "include"))
		os.cp("DUtils/*.h", path.join(target:installdir(), "include"))
	end)
end)
