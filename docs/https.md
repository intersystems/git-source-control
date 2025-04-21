## Setting up HTTPS

We highly recommend that you use SSH to connect to your repositories. If this is not possible, then HTTPS is another option.

First, add your remote repo in the settings page, or during the Configure step. (Note: do NOT provide a username in the url)

After this, you have to authenticate using OAuth tokens. To do this, press "Authenticate" in the bottom left of the Embedded Git UI, or from the Source Control Menu.

### Authentication

If you have not already done so, create a new OAuth app in github or gitlab. The "Authorization callback URL" should be &lt;your url&gt;/isc/studio/usertemplates/gitsourcecontrol/oauth2.csp.

Remember to save the ClientID and ClientSecret. Once this is finished, you can enter your information into the authentication page.
![Screenshot of authentication page](/images/auth.png)

Once all of the information is correct, you can press Save. This will redirect you to either gitlab or github in order to authorize your application. After this is done, you will be redirected back to the authentication page, and you should be good to go!


