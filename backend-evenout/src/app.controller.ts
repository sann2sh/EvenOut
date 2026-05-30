import { Controller, Get, Res } from '@nestjs/common';
import { Public } from './common/decorators/public.decorator';

@Controller()
export class AppController {
  @Public()
  @Get('health')
  getHealth(): { status: string; timestamp: string } {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }

  @Public()
  @Get()
  getAuthCallback(@Res() res: any) {
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Auth Successful</title>
        <style>
          body { font-family: sans-serif; padding: 2rem; max-width: 600px; margin: auto; }
          pre { background: #eee; padding: 1rem; overflow-x: auto; border-radius: 4px; }
        </style>
      </head>
      <body>
        <h2>Authentication Successful!</h2>
        <p>Here is your Access Token for Postman:</p>
        <pre id="token">Loading...</pre>
        
        <script>
          // The token is in the URL hash, e.g. #access_token=...
          const hash = window.location.hash.substring(1);
          const params = new URLSearchParams(hash);
          const token = params.get('access_token');
          
          if (token) {
            document.getElementById('token').textContent = token;
          } else {
            document.getElementById('token').textContent = "No token found in URL hash.";
          }
        </script>
      </body>
      </html>
    `;
    res.type('text/html').send(html);
  }
}
