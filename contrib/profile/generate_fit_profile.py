from garmin_fit_sdk import profile
import msgpack
from pathlib import Path
from typing import Dict, Any, Optional, Union


def write_msgpack(
    data: Dict[Any, Any],
    filepath: Union[str, Path],
    create_dirs: bool = True,
    use_bin_type: bool = True
) -> None:
    """
    Write a Python dictionary to a msgpack file with robust error handling.
    
    Args:
        data: Dictionary to serialize and write to file
        filepath: Path where the msgpack file will be written
        create_dirs: If True, creates parent directories if they don't exist
        use_bin_type: If True, uses the binary type for serialization (recommended)
        
    Raises:
        TypeError: If data is not a dictionary
        ValueError: If filepath is empty or invalid
        OSError: If file cannot be written due to permissions or disk issues
        msgpack.PackException: If data cannot be serialized
        
    Example:
        >>> data = {"name": "John", "age": 30, "scores": [95, 87, 92]}
        >>> write_msgpack(data, "output.msgpack")
    """
    # Validate input
    if not isinstance(data, dict):
        raise TypeError(f"Expected dict, got {type(data).__name__}")
    
    if not filepath:
        raise ValueError("Filepath cannot be empty")
    
    # Convert to Path object for better handling
    filepath = Path(filepath)
    
    # Validate filepath
    if filepath.is_dir():
        raise ValueError(f"Filepath points to a directory: {filepath}")
    
    # Create parent directories if requested
    if create_dirs and filepath.parent != Path():
        try:
            filepath.parent.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            raise OSError(f"Failed to create directory {filepath.parent}: {e}")
    
    # Write to msgpack file
    try:
        with open(filepath, 'wb') as f:
            msgpack.pack(data, f, use_bin_type=use_bin_type)
    except msgpack.PackException as e:
        raise msgpack.PackException(f"Failed to serialize data: {e}")
    except OSError as e:
        raise OSError(f"Failed to write to file {filepath}: {e}")


def main():
    prof = profile.Profile # Load Profile Dict from garmin_fit_sdk
    print("Writing profile.msg (MsgPack Format)")
    write_msgpack(prof, "profile.msg")

if __name__ == "__main__":
    main()
