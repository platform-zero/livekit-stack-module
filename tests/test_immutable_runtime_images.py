import re,unittest
from pathlib import Path
EXPECTED=['livekit/livekit-server:v1.11.0@sha256:100b9a870616d02f5e3795b34e0b593b5054a26f8131a94fd3fa322ed3154b16', 'ghcr.io/element-hq/lk-jwt-service:0.4.4@sha256:38d80f52169cff5c8db18ed7714d71ce20132fee0b9ec7ddc2724d09f1eee7fa']
PINS=[['livekit/livekit-server:v1.11.0', '100b9a870616d02f5e3795b34e0b593b5054a26f8131a94fd3fa322ed3154b16'], ['ghcr.io/element-hq/lk-jwt-service:0.4.4', '38d80f52169cff5c8db18ed7714d71ce20132fee0b9ec7ddc2724d09f1eee7fa']]
def accept(ref,base,digest):
 if not re.fullmatch(r'[0-9a-f]{64}',digest) or ref!=base+'@sha256:'+digest:raise ValueError('unreviewed or mutable source reference')
class ImmutableRuntimeSource(unittest.TestCase):
 def test_actual_source_image_list(self):
  refs=re.findall(r'(?m)^\s*image:\s*["\']?([^"\'\s#]+)',(Path(__file__).parents[1]/'stack.runtime.yaml').read_text())
  self.assertEqual(EXPECTED,refs)
  for base,digest in PINS:accept(base+'@sha256:'+digest,base,digest)
 def test_floating_rejected(self):
  for base,digest in PINS:
   with self.subTest(base=base),self.assertRaises(ValueError):accept(base.rsplit(':',1)[0]+':latest',base,digest)
 def test_version_only_rejected(self):
  for base,digest in PINS:
   with self.subTest(base=base),self.assertRaises(ValueError):accept(base,base,digest)
 def test_malformed_digest_rejected(self):
  for base,digest in PINS:
   for bad in ['a'*63,'g'*64,'A'*64,'a'*65,'']:
    with self.subTest(base=base,bad=bad),self.assertRaises(ValueError):accept(base+'@sha256:'+bad,base,digest)
 def test_wrong_digest_rejected(self):
  for base,digest in PINS:
   with self.subTest(base=base),self.assertRaises(ValueError):accept(base+'@sha256:'+'0'*64,base,digest)
if __name__=='__main__':unittest.main()
