"""Published packages must survive failed or ambiguous GitHub lookups."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('release_state', ROOT / 'tools/release_state.py')
release_state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_state)


class ReleaseStateTests(unittest.TestCase):
    def test_published_release_cannot_be_rebuilt(self):
        self.assertFalse(release_state.should_build(0, 'HTTP/2.0 200 OK\n\n{"draft":false}'))

    def test_draft_can_resume_and_confirmed_absence_can_build(self):
        self.assertTrue(release_state.should_build(0, 'HTTP/2.0 200 OK\r\n\r\n{"draft":true}'))
        self.assertTrue(release_state.should_build(1, 'HTTP/2.0 404 Not Found\n\n{"message":"Not Found"}'))

    def test_api_and_network_errors_cannot_overwrite_a_release(self):
        for response in ('', 'HTTP/2.0 401 Unauthorized\n\n{}',
                         'HTTP/2.0 403 Forbidden\n\n{}', 'HTTP/2.0 503 Service Unavailable\n\n{}'):
            with self.subTest(response=response), self.assertRaises(RuntimeError):
                release_state.should_build(1, response)

    def test_incomplete_metadata_is_not_permission_to_build(self):
        for body in ('{}', '{"draft":null}', '{"draft":"false"}', '<html>proxy error</html>'):
            with self.subTest(body=body), self.assertRaises(RuntimeError):
                release_state.should_build(0, 'HTTP/2.0 200 OK\n\n' + body)


if __name__ == '__main__':
    unittest.main()
