from pyngrok import ngrok
from pyngrok.conf import PyngrokConfig


# Use your working ngrok.exe path
config = PyngrokConfig(ngrok_path="C:/ngrok/ngrok.exe")

# Open a tunnel on port 8000 (or your backend port)
public_url = ngrok.connect(8000, pyngrok_config=config)

print("🔗 Public URL:", public_url)
