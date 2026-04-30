import cv2
import numpy as np
from typing import Optional, Tuple
from engine.src.core.logger import logger

def find_template(
    screen_path: str, 
    template_path: str, 
    threshold: float = 0.8
) -> Optional[Tuple[int, int]]:
    """
    Find template image in screen image.
    Returns center (x, y) if found, else None.
    """
    try:
        screen = cv2.imread(screen_path)
        template = cv2.imread(template_path)
        
        if screen is None or template is None:
            logger.error("Could not read screen or template image")
            return None
            
        result = cv2.matchTemplate(screen, template, cv2.TM_CCOEFF_NORMED)
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
        
        if max_val >= threshold:
            h, w = template.shape[:2]
            center_x = max_loc[0] + w // 2
            center_y = max_loc[1] + h // 2
            logger.info(f"Template found at ({center_x}, {center_y}) with confidence {max_val}")
            return (center_x, center_y)
        
        logger.info(f"Template not found. Best match confidence: {max_val}")
        return None
    except Exception as e:
        logger.error(f"Error during template matching: {e}")
        return None
