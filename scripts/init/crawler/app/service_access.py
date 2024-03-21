import sys
import requests

def test_access(url, token):
    url = "https://management.azure.com/subscriptions?api-version=2020-01-01"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    print(f"  {response.status_code}: management.azure.com")

def main():
    if len(sys.argv) < 3:
        print("Usage: python service_access.py <url> <token>")
        sys.exit(1)

    url = sys.argv[1]
    token = sys.argv[2]
    test_access(url, token)

if __name__ == "__main__":
    main()
