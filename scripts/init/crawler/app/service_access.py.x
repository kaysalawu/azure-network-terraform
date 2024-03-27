import sys
import requests

def test_access(url, token=None):
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            print(response.status_code)
            sys.exit(response.status_code)
    except requests.exceptions.RequestException as e:
        print(e.response.status_code if e.response else "000")
        sys.exit(1 if not e.response else e.response.status_code)

def main():
    if len(sys.argv) < 2:
        print("Usage: python service_access.py <url> [token]")
        sys.exit(1)

    url = sys.argv[1]
    token = sys.argv[2] if len(sys.argv) > 2 else None
    test_access(url, token)

if __name__ == "__main__":
    main()
