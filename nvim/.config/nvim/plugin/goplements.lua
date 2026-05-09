-- Goplements: show interface implementations
require('goplements').setup {
  prefix = {
    interface = 'implemented by: ',
    struct = 'implements: ',
  },
  display_package = false,
  namespace_name = 'goplements',
  highlight = 'Goplements',
}
