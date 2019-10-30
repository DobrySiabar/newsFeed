# newsFeed

# No additional settings are required to run the application! Just download the project and open NewsFeed.xcodeproj file, build and run.

# Description:

Using a free News API (https://newsapi.org), an app can display and filter news for last 7 days.

Each cell contain preview image (if no image received, use fixed placeholder instead), title and short description (1-3 lines of text). If description is more than 3 lines, use blue "Show More" button to see full description.

When application runs, user sees  screen with news for last 24 hours only. When user reaches the end of current news list, then next news page for previous day downloading and added to the bottom etc. till list contains 7-days news. In this case pagination is disabled.

User is able to refresh news list by pull-to-refresh. Days counter is also reset.
Just drag from top to the bottom to refresh feed.

Also search bar has also been added at the top of main screen. It allows user to filter currently downloaded news by title. Start typing to filter.

The user also has the opportunity to save specific news by holding on cell with selected news. Images from the news are storing on the device. User can delete news by right-to-left swipe.
CoreData has been selected as a storage method. 
