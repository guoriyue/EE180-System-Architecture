import os
import shutil

TESTS_DIR = './tests'

for test_dir in os.listdir(TESTS_DIR):
    # Check if test_dir ends with "-hazard"
    if test_dir.endswith('-hazard'):
        continue

    # Check if corresponding "-hazard" directory exists
    hazard_dir = os.path.join(TESTS_DIR, '{}-hazard'.format(test_dir))
    if os.path.exists(hazard_dir):
        continue

    # Duplicate test directory to create hazard directory
    shutil.copytree(os.path.join(TESTS_DIR, test_dir), hazard_dir)

    # Modify .S file in hazard directory to delete nop instructions
    s_file = os.path.join(hazard_dir, '{}.S'.format(test_dir))
    os.system('sed -i "/nop/d" {}'.format(s_file))

    # Rename .S file to add "-hazard" suffix
    os.rename(s_file, os.path.join(hazard_dir, '{}-hazard.S'.format(test_dir)))