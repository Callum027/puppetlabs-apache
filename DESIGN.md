What would we do, if we could do breaking changes?
==================================================

Get rid of all `<IfModule>` directives
--------------------------------------

Our module controls the configuration files, by definition, it knows which
modules to include. As such, it would vastly improve the readability of the
generated configuration files, as well an administrators ability to reason
about them, if we reduce the mental overhead by removing `<IfModule>`

Get rid of all `<IfVersion>` directives
---------------------------------------

In the same vein, we can get rid of `<IfVersion>`, and instead just
*consistently* make use of `scope.function_versioncmp()`.

Full Support of `mod_macro`
---------------------------

I don't think I've written this much httpd configuration in four years, since I
started using this module, exclusively. Thanks to the current design, there is
no simple way (certainly none in hiera) to create a template with a few
variables that are exchanged.

`mod_macro` allows for these templates to be self-defined, and reused in any
context they fit. Our module should allow the declaration of custom macros,
and their use in `apache::vhost`. Nice to have: generate vhosts from macros.