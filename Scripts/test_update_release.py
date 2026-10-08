import base64
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from update_release import appcast, verify_archive

class UpdateReleaseTests(unittest.TestCase):
    def test_real_signature_accepts_final_bytes_and_rejects_mutation(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root/'archive.zip'; archive.write_bytes(b'final stapled archive bytes')
            subprocess.run(['openssl','genpkey','-algorithm','ED25519','-out',str(root/'key')],check=True,capture_output=True)
            subprocess.run(['openssl','pkeyutl','-sign','-inkey',str(root/'key'),'-rawin','-in',str(archive),'-out',str(root/'sig')],check=True,capture_output=True)
            key = subprocess.check_output(['openssl','pkey','-in',str(root/'key'),'-pubout','-outform','DER'])[-32:]
            sig = base64.b64encode((root/'sig').read_bytes()).decode()
            public = base64.b64encode(key).decode()
            verify_archive(archive,sig,public)
            archive.write_bytes(b'changed bytes after signing')
            with self.assertRaisesRegex(ValueError,'does not verify'):verify_archive(archive,sig,public)

    def test_feed_requires_complete_immutable_archive(self):
        release={'version':'1.2.3','build':'123','sparkle':{'enclosure':'Fixture-1.2.3.zip','length':100,'edSignature':base64.b64encode(bytes(64)).decode()}}
        asset={'id':19,'name':'Fixture-1.2.3.zip','size':100}
        xml=appcast(release,'test/Fixture',asset,'Fixed the app','15.0')
        enclosure=ET.fromstring(xml).find('./channel/item/enclosure')
        self.assertEqual(enclosure.attrib['url'],'https://api.github.com/repos/test/Fixture/releases/assets/19?filename=Fixture-1.2.3.zip')
        for change in [{'id':0},{'size':101},{'name':'Other.zip'}]:
            with self.assertRaises(ValueError):appcast(release,'test/Fixture',asset|change,'Notes')

if __name__=='__main__':unittest.main()
