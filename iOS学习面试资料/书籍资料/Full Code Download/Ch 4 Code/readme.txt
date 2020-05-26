**** SHARING ARTICLES:

As part of the payload generation examples a sample server script was included. There are two required changes to the Share* operations in order for communication between the application and your deployed server script.

1) ShareArticlesOperationJSON.m Line 22
- Replace "<server>" with the path to the script. This path can be something hosted on the web or locally on your machine.

2) ShareArticlesOperationXML.m Line 22
- Replace "<server>" with the path to the script. This path can be something hosted on the web or locally on your machine.

**** FETCHING OFFLINE CONTENT:

This application was designed to fetch live information directly from the web. It is possible that something at those data sources may change, such as content structure, resource location, etc. In the event that one or more of the data sources change, we have archived some content used for testing in order to enable an 'offline' mode.

In order for the application to fetch content locally the following changes need to be made:
1) FetchTopStoriesOperation.m
- Comment line 13
- Uncomment line 14 and update the the path in the kURL constant to the local location of the "News Content" folder which was packaged as part of App.zip

2) FetchPostContentOperation.m
- Update the kURLPrefix constant to the local path for the files. This path is likely the same that was used in Step 1.
- Comment line 29
- Uncomment line 30