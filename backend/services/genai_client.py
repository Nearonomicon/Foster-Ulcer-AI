import os
from dotenv import load_dotenv
from google import genai
from google.genai import types


load_dotenv()
my_key = os.getenv("GEMINI_API_KEY")

genai_model = "gemini-2.5-flash"
client = genai.Client(api_key=my_key)

safety_config = [
    types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="BLOCK_NONE"),
    types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="BLOCK_NONE"),
    types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="BLOCK_NONE"),
    types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="BLOCK_NONE"),
]
