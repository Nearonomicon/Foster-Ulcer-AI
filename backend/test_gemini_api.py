from services.genai_client import client, genai_model, safety_config
from google.genai import types


def main() -> None:
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents="Hello Gemini",
        config=types.GenerateContentConfig(
            safety_settings=safety_config,
            temperature=0.1,
        ),
    )

    print("Prompt: Hello Gemini")
    print("Response:")
    print(response.text or "<empty response>")


if __name__ == "__main__":
    main()
