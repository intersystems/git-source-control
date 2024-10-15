# A Brief Introduction to Source Control

Source control, or change control, is a system that helps teams manage and track changes to their work, with particulaar relevancy to software development. It helps produce a definitive record of the hostory of the product, as well as allow for revisiting earlier versions and previous changes. This means that multiple people can work on the same thing together without getting in each other's way. You can see who made changes, when they were made, and what these changes were addressing. If any change leads to issues, this allows teams to quickly roll back to a previous version that is working, as well as identify which specific change may have caused the issue.

## Key Concepts

### Versioning

Each change or batch of changes is saved as a new version. This allows users and developers to reference or revert to previous versions when necessary (git-source-control is itself versioned)

### History Tracking

Since every change is logged, source control provides users with a complete history of a project, allowing anyone to track its evolution, as well as pinpoint causes and the nature of issues that may arise

### Branching

Branching involves creating distinct copies of the same product, so that changes can be made and tested in isolation, without affecting other users and changes. These "branches" can be merged to bring changes back to the main product.


### Example of source control

A teammate and I are working on an article. I am focusing on the introduction and conclusion, while they focus on the main paragraph. To avoid conflicts, we create seperate copies (branches) of the article to work on. When I am finished with my work, I can merge the changes I have made back into the main article. Others can see the exact changes I have made, and if anyone else is working on the same section we won't run into problems because I have my own separate copy.
