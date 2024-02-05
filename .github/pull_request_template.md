# Description

Please write a summary of what the changes does; explaining your design choices if necessary.

If relevant, describe linked issues:
Closes #(issue)

Please also disclose whether there are any API changes that may effect users of the plugin.

<!-- For drafts, fill this in as you go; if you are done, make sure these are all done -->
#Checklist (replace space with X in the brackets to complete)

- [ ] I have made corresponding changes to the documentation if applicable.
- [ ] My code has passed the following test:
  - Reload the editor(Project->Reload current project), since godot plugins are fiddly and some errors only shows up after the plugin context has been reloaded.
  - run the res://tests/logtest.tscn scene.
  - This should produce several error messages, among one that halts the test execution and brings up the editor debugger.
  - press ![bild](https://github.com/albinaask/Log/assets/11806563/4e4b3d51-793f-496e-8193-c96b5884f1cc) once.
  - Now this message ![bild](https://github.com/albinaask/Log/assets/11806563/c3102b55-21b3-438e-a420-56971ad98d39) should show in the engine log.
- [ ] I have correctly bumped the version in the config.cfg according to the following:
  - Has form x.y.z
  - x is bumped if API breaking changes is made, these are merged restrictively.
  - y is bumped if API is added upon or modified in a way that is backwards compatible.
  - z is bumped if bugs are fixed or only internal things are changed or rearranged that doesn't change the API at all.
  - Documentation changes or comments needs no version change.
  - Read more [here](https://semver.org/) if unclear.
     
<!-- Thanks to: https://github.com/Team-EnderIO/EnderIO/blob/dev/1.20.1/.github/pull_request_template.md?plain=1 for the building blocks of this template -->
