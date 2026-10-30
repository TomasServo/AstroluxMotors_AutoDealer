Astrolux Motors — admin banking documentation

Start here: docs/PRIVATE-BANK-INTEGRATION.txt
Private-bank template: docs/examples/PrivateBankAdapter.lua.example

Banking is optional. Carried cash works without a banking mod. The included
TSB adapter detects the TSB server bridge when available. Admins may provide
their own optional adapters; no third-party bank bridge is bundled.

The template is an example, not an enabled runtime script. Implement and test
your bank's transaction API before renaming it to .lua in a separate adapter mod.
