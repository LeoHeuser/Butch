# Library Description

The ButchKit is a helpful SDK containing small tools and modifiers to assist with the development of Swift applications for all Apple platforms. It contains functions that are not developed by Apple, but which could be useful in many projects.



# Requirements

Minimum version of iOS and iPadOS is 17.0. Minimum macOS is 14.0.

# General Behaviour

- Remember to declare elements as 'public' so that they can be used in a library

# Logging

Follow `Documentation/LoggingStrategy.md`. Its "Rules for agents" section at the end is the checklist — read it before writing a log statement. Three rules matter enough to repeat here, because getting them wrong is not recoverable after the fact:

- NEVER use `print` or `NSLog` for diagnostics — use `os.Logger`
- Never mark an interpolated value `public` if it can contain user data
- Use `notice` or higher for anything that must be visible in the field; `debug` and `info` do not survive there
