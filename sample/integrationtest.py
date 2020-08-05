import unittest
import requests

class TestRest(unittest.TestCase):
    '''
    Sample Integration Test Cases for https://github.com/Azure-Samples/helm-charts/tree/master/chart-source/azure-vote
    '''
    azure_vote_endpoint = "http://localhost:8080"

    def test_1_title_check(self):
        """
        [Test Case 1]: Basic Integration Test Title Check - GET - http://azure-vote-front/
        """
        print("\n[Test Case 1]: Basic Integration Test Title Check - GET - http://azure-vote-front/")
        url = self.azure_vote_endpoint + '/'
        response = requests.get(url=url)
        status_code = response.status_code
        self.assertEqual(status_code, 200)
        request_body = response.text
        self.assertIn("Kind Integration Test Framework Demo", request_body)
    
    def test_2_button_check_1(self):
        """
        [Test Case 2]: Basic Integration Test Button Check 1 - GET - http://azure-vote-front/
        """
        print("\n[Test Case 1]: Basic Integration Test Button Check 1 - GET - http://azure-vote-front/")
        url = self.azure_vote_endpoint + '/'
        response = requests.get(url=url)
        status_code = response.status_code
        self.assertEqual(status_code, 200)
        request_body = response.text
        self.assertIn("Kubernetes", request_body)
    
    def test_3_button_check_2(self):
        """
        [Test Case 3]: Basic Integration Test Button Check 2 - GET - http://azure-vote-front/
        """
        print("\n[Test Case 1]: Basic Integration Test Button Check 2 - GET - http://azure-vote-front/")
        url = self.azure_vote_endpoint + '/'
        response = requests.get(url=url)
        status_code = response.status_code
        self.assertEqual(status_code, 200)
        request_body = response.text
        self.assertIn("DockerSwarm", request_body)
    
    def test_4_default_vote_check(self):
        """
        [Test Case 3]: Basic Integration Test Default Votes - GET - http://azure-vote-front/
        """
        print("\n[Test Case 1]: Basic Integration Test Default Votes - GET - http://azure-vote-front/")
        url = self.azure_vote_endpoint + '/'
        response = requests.get(url=url)
        status_code = response.status_code
        self.assertEqual(status_code, 200)
        request_body = response.text
        self.assertIn("Kubernetes - 0 | DockerSwarm - 0", request_body)

if __name__ == '__main__':
    unittest.main()